/*
 * The Listening Room Project
 * Copyright (C) 2025  MAINTAINERS
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import TheListeningRoomExtensionSDK
import Foundation
import MediaPlayer
import os
import SwiftData

@Observable @MainActor final class Player {
    static let logger = Logger(subsystem: "io.github.decarbonization.TheListeningRoom", category: "Player")
    
    init(modelContext: ModelContext) {
        self.engineEventSubscriber = AsyncSubscriber()
        self.queueChangeSubscruber = AsyncSubscriber()
        self.engine = SFBPlaybackEngine()
        self.queue = Queue(context: modelContext)
        
        engineEventSubscriber.activate(consuming: engine.events) { [weak self] event, stop in
            await self?.onEngineEvent(event)
        }
        queueChangeSubscruber.activate(consuming: queue.observeChanges(to: \.itemIDs)) { [weak self] _, stop in
            await self?.onQueueChange()
        }
    }
    
    private let engineEventSubscriber: AsyncSubscriber
    private let queueChangeSubscruber: AsyncSubscriber
    private var engine: any ListeningRoomPlaybackEngine
    private var heartBeat: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }
    
    let queue: Queue<PersistentIdentifier, ModelContext>
    
    var playingItem: ListeningRoomPlayingItem? {
        access(keyPath: \.playingItem)
        return engine.playingItem
    }
    
    var playbackState: ListeningRoomPlaybackState? {
        access(keyPath: \.playbackState)
        return engine.playbackState
    }
    
    var totalTime: TimeInterval {
        access(keyPath: \.totalTime)
        return engine.totalTime ?? 0
    }
    
    var currentTime: TimeInterval {
        get {
            access(keyPath: \.currentTime)
            return engine.currentTime ?? 0
        }
        set {
            Task {
                try await engine.seek(toTime: newValue)
                withMutation(keyPath: \.currentTime) {
                    // Do nothing.
                }
            }
        }
    }
    
    func playItem(withID itemID: PersistentIdentifier) async throws {
        do {
            guard engine.isPlayingFromQueue,
                  queue.itemIDs.contains(itemID),
                  let song = queue.item(of: Song.self, withID: itemID) else {
                throw CocoaError(.fileNoSuchFile)
            }
            
            try await engine.enqueue(ListeningRoomPlayingItem(song), playNow: true)
            
            withMutation(keyPath: \.currentTime) {
                heartBeat = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                    MainActor.assumeIsolated {
                        self?.withMutation(keyPath: \.currentTime) {
                            // Do nothing.
                        }
                    }
                }
            }
        } catch {
            do {
                try await stop()
            } catch {
                Self.logger.warning("Could not stop playback engine after enqueue error, reason: \(error)")
            }
            throw error
        }
    }
    
    func stop() async throws {
        try await engine.stop()
        withMutation(keyPath: \.currentTime) {
            heartBeat = nil
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }
    
    func pause() async throws {
        try await engine.pause()
    }
    
    func resume() async throws {
        try await engine.resume()
    }
    
    func skipPrevious() async throws {
        if engine.isPlayingFromQueue,
           let playingItem = engine.playingItem,
           let newItemID = queue.previousItemID(preceding: playingItem.id) {
            try await playItem(withID: newItemID)
        } else {
            try await stop()
        }
    }
    
    func skipNext() async throws {
        if engine.isPlayingFromQueue,
           let playingItem = engine.playingItem,
           let newItemID = queue.nextItemID(following: playingItem.id) {
            try await playItem(withID: newItemID)
        } else {
            try await stop()
        }
    }
    
    private func onEngineEvent(_ event: ListeningRoomPlaybackEvent) async {
        switch event {
        case .playbackStateDidChange:
            withMutation(keyPath: \.playbackState) {
                // Do nothing for now.
            }
        case .playingItemChanged:
            withMutation(keyPath: \.playingItem) {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = engine.playingItem?.mpItemProperties
            }
        case .encounteredError(let domain, let code, let userInfo):
            Self.logger.error("Playback engine encountered error: \(domain) (\(code)) \(userInfo)")
            do {
                try await stop()
            } catch {
                Self.logger.error("Could not stop upon encountering an error, reason: \(error)")
            }
        case .endOfAudio(let wantsQueueToAdvance):
            guard wantsQueueToAdvance else {
                return
            }
            do {
                try await skipNext()
            } catch {
                Self.logger.error("Could not advance to next track, reason: \(error)")
            }
        }
    }
    
    private func onQueueChange() async {
        guard engine.isPlayingFromQueue,
              let playingItem = engine.playingItem else {
            return
        }
        if !queue.itemIDs.contains(playingItem.id) {
            do {
                try await stop()
            } catch {
                Self.logger.error("Could not stop playback when playing item was removed from queue, reason: \(error)")
            }
        }
    }
}
