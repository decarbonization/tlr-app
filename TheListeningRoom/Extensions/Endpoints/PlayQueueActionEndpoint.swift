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
    func callAsFunction(_ action: ListeningRoomHostPlayQueueAction, with context: ListeningRoomXPCContext) async throws -> Bool {
        switch action {
        case .pause:
            guard context.playQueue.playbackState == .playing else {
                return false
            }
            context.playQueue.pause()
            return true
        case .resume:
            guard context.playQueue.playbackState == .paused else {
                return false
            }
            context.playQueue.resume()
            return true
        case .previousTrack:
            guard context.playQueue.canSkipPreviousTrack else {
                return false
            }
            try context.playQueue.previousTrack()
            return true
        case .nextTrack:
            guard context.playQueue.canSkipNextTrack else {
                return false
            }
            try context.playQueue.nextTrack()
            return true
        }
    }
}
