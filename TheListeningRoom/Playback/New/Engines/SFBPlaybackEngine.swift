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
@preconcurrency import SFBAudioEngine

extension ListeningRoomPlaybackState {
    static func from(_ sfbPlaybackState: AudioPlayer.PlaybackState) -> Self {
        switch sfbPlaybackState {
        case .paused:
            return .paused
        case .playing:
            return .playing
        case .stopped:
            return .stopped
        @unknown default:
            fatalError("Unknown playback state \(sfbPlaybackState.rawValue)")
        }
    }
}

final class SFBPlaybackEngine: NSObject, ListeningRoomPlaybackEngine, AudioPlayer.Delegate {
    override init() {
        let (stream, continuation) = AsyncStream.makeStream(of: PlaybackEvent.self)
        audioPlayer = AudioPlayer()
        eventSink = continuation
        events = stream
        _playingItem = .init(initialState: nil)
        
        super.init()
        
        audioPlayer.delegate = self
    }
    
    deinit {
        eventSink.finish()
    }
    
    private let audioPlayer: AudioPlayer
    private let eventSink: AsyncStream<PlaybackEvent>.Continuation
    private let _playingItem: OSAllocatedUnfairLock<ListeningRoomPlayingItem?>
    
    // MARK: - PlaybackEngine
    
    let events: AsyncStream<PlaybackEvent>
    
    var isPlayingFromQueue: Bool {
        true
    }
    
    var playingItem: ListeningRoomPlayingItem? {
        _playingItem.withLock { $0 }
    }
    
    var playbackState: ListeningRoomPlaybackState {
        .from(audioPlayer.playbackState)
    }
    
    var totalTime: TimeInterval? {
        audioPlayer.totalTime
    }
    
    var currentTime: TimeInterval? {
        audioPlayer.currentTime
    }
    
    var volume: Float {
        audioPlayer.volume
    }
    
    func setVolume(_ newVolume: Float) async throws {
        try audioPlayer.setVolume(newVolume)
    }
    
    func enqueue(_ itemToPlay: ListeningRoomPlayingItem,
                 playNow: Bool) async throws {
        do {
            let itemURL = itemToPlay.assetURL
            guard itemURL.startAccessingSecurityScopedResource() else {
                throw CocoaError(.fileReadNoPermission, userInfo: [
                    NSLocalizedDescriptionKey: "Could not extend sandbox for file <\(itemURL)>",
                    NSURLErrorKey: itemURL
                ])
            }
            try audioPlayer.enqueue(itemURL, immediate: true)
            if itemToPlay.startTime > 0 {
                try await seek(toTime: itemToPlay.startTime)
            }
            if playNow {
                try audioPlayer.play()
            }
            _playingItem.withLock { playingItem in
                playingItem = itemToPlay
            }
            eventSink.yield(.playingItemChanged)
        } catch {
            try await stop() // Never throws
            throw error
        }
    }
    
    func skipPreviousInQueue() async throws -> Bool {
        false
    }
    
    func skipNextInQueue() async throws -> Bool {
        false
    }
    
    func seek(toTime newTime: TimeInterval) async throws {
        if !audioPlayer.seek(time: newTime) {
            throw CocoaError(.featureUnsupported, userInfo: [
                NSLocalizedDescriptionKey: "Could not seek to time \(newTime)",
            ])
        }
    }
    
    func pause() async throws {
        audioPlayer.pause()
    }
    
    func resume() async throws {
        switch audioPlayer.playbackState {
        case .stopped where !audioPlayer.queueIsEmpty:
            try audioPlayer.play()
        case .paused:
            audioPlayer.resume()
        default:
            break // Do nothing.
        }
    }
    
    func stop() async throws {
        audioPlayer.stop()
        audioPlayer.clearQueue()
        _playingItem.withLock { playingItem in
            playingItem = nil
        }
        eventSink.yield(.playingItemChanged)
    }
    
    // MARK: - AudioPlayer.Delegate
    
    func audioPlayer(_ audioPlayer: AudioPlayer, playbackStateChanged playbackState: AudioPlayer.PlaybackState) {
        eventSink.yield(.playbackStateDidChange)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, encounteredError error: any Error) {
        eventSink.yield(.encounteredError(error))
    }
    
    func audioPlayerEndOfAudio(_ audioPlayer: AudioPlayer) {
        eventSink.yield(.endOfAudio(lastItem: playingItem))
    }
}
