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

import Foundation
import TheListeningRoomExtensionSDK

struct PlayQueueActionEndpoint: ListeningRoomXPCEndpoint {
    let player: Player
    
    func callAsFunction(_ action: ListeningRoomHostPlayQueueAction) async throws -> Bool {
        switch action {
        case .pause:
            guard player.playbackState == .playing else {
                return false
            }
            try await player.pause()
            return true
        case .resume:
            guard player.playbackState == .paused else {
                return false
            }
            try await player.resume()
            return true
        case .previousTrack:
            try await player.skipPrevious()
            return true
        case .nextTrack:
            try await player.skipNext()
            return true
        }
    }
}
