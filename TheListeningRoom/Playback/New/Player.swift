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
import os
import SwiftData

@Observable @MainActor final class Player {
    static let logger = Logger(subsystem: "io.github.decarbonization.TheListeningRoom", category: "Player")
    
    init(context: ModelContext) {
        self.eventSubscriber = AsyncSubscriber()
        self.engine = SFBPlaybackEngine()
        self.queue = PlaybackQueue()
        self.context = context
        
        eventSubscriber.subscribe(to: engine.events) { [weak self] event in
            await self?.onEngineEvent(event)
        }
    }
    
    private let eventSubscriber: AsyncSubscriber
    private var engine: any ListeningRoomPlaybackEngine
    let queue: PlaybackQueue<PersistentIdentifier>
    let context: ModelContext
    
    var playingItem: ListeningRoomPlayingItem? {
        access(keyPath: \.playingItem)
        return engine.playingItem
    }
    
    var playbackState: ListeningRoomPlaybackState? {
        access(keyPath: \.playbackState)
        return engine.playbackState
    }
    
    func playItem(withID itemID: PersistentIdentifier) async throws {
        do {
            guard queue.itemIDs.contains(itemID),
                  let song: Song = context.registeredModel(for: itemID) else {
                throw CocoaError(.fileNoSuchFile)
            }
            
            try await engine.enqueue(ListeningRoomPlayingItem(song), playNow: true)
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
    }
    
    func pause() async throws {
        try await engine.pause()
    }
    
    func resume() async throws {
        try await engine.resume()
    }
    
    func skipPrevious() async throws {
        if let playingItem = engine.playingItem,
           let newItemID = queue.previousItemID(preceding: playingItem.id) {
            try await playItem(withID: newItemID)
        } else {
            try await stop()
        }
    }
    
    func skipNext() async throws {
        if let playingItem = engine.playingItem,
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
                // Do nothing for now.
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
}
