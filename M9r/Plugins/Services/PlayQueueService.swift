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
        }
        
        var playbackState: PlaybackState
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
    
    func receive(_ message: Message, with context: PluginServiceContext) async throws -> Reply {
        try await Task { @MainActor in
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
        }.value
        let playbackState: Reply.PlaybackState
        switch playQueue.playbackState {
        case .stopped:
            playbackState = .stopped
        case .playing:
            playbackState = .playing
        case .paused:
            playbackState = .paused
        @unknown default:
            fatalError()
        }
        return Reply(playbackState: playbackState)
    }
}
