/*
 * M9r
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

import Foundation
import os
import SFBAudioEngine

struct PlayQueueService: PluginService {
    struct Message: Codable {
        enum Command: String, Codable {
            case state
            case previous
            case next
            case pause
            case resume
        }
        
        var command: Command
    }
    
    struct Reply: Codable {
        enum PlaybackState: String, Codable {
            case stopped
            case playing
            case paused
            
            static func from(_ playbackState: AudioPlayer.PlaybackState) -> Self {
                switch playbackState {
                case .stopped:
                    return .stopped
                case .playing:
                    return .playing
                case .paused:
                    return .paused
                @unknown default:
                    fatalError()
                }
            }
        }
        
        var playbackState: PlaybackState
    }
    
    private final class Publisher: PluginEventSinkPublisher {
        private let _isStopped = OSAllocatedUnfairLock(initialState: false)
        
        var isStopped: Bool {
            _isStopped.withLock { $0 }
        }
        
        func stop() {
            _isStopped.withLock { isStopped in
                isStopped = true
            }
        }
    }
    
    static var name: String {
        "playQueue"
    }
    
    static var requiredPermissions: Set<Plugin.Permission> {
        [.playQueue]
    }
    
    init(playQueue: PlayQueue) {
        self.playQueue = playQueue
    }
    
    let playQueue: PlayQueue
    
    func beginDispatchingEvents(into eventSink: any PluginEventSink) -> any PluginEventSinkPublisher {
        let publisher = Publisher()
        @Sendable func subscribe() {
            withObservationTracking {
                withExtendedLifetime(playQueue.playbackState) {
                    // do nothing.
                }
            } onChange: {
                guard !publisher.isStopped else {
                    return
                }
                Task {
                    try await eventSink.dispatchEvent(of: "playbackstatechanged", with: Reply.PlaybackState.from(playQueue.playbackState))
                }
                subscribe()
            }
        }
        subscribe()
        return publisher
    }
    
    func receive(_ message: Message, with context: PluginServiceContext) async throws -> Reply {
        try await MainActor.run {
            switch message.command {
            case .state:
                break
            case .previous:
                try playQueue.previousTrack()
            case .next:
                try playQueue.nextTrack()
            case .pause:
                playQueue.pause()
            case .resume:
                playQueue.resume()
            }
        }
        return Reply(playbackState: .from(playQueue.playbackState))
    }
}
