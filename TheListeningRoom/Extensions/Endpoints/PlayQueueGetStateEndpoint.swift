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
import ListeningRoomExtensionSDK
import SFBAudioEngine

struct PlayQueueGetStateEndpoint: ListeningRoomXPCEndpoint {
    init(_ playQueue: PlayQueue) {
        self.playQueue = playQueue
    }
    
    private let playQueue: PlayQueue
    
    func callAsFunction(_ request: ListeningRoomHostPlayQueueGetState) async throws -> ListeningRoomHostPlayQueueState {
        ListeningRoomHostPlayQueueState(from: playQueue)
    }
}

extension ListeningRoomHostPlayQueueState {
    fileprivate init(from playQueue: PlayQueue) {
        self.init(playbackState: .from(playQueue.playbackState),
                  canSkipPreviousTrack: playQueue.canSkipPreviousTrack,
                  canSkipNextTrack: playQueue.canSkipNextTrack,
                  playingItemIndex: playQueue.playingIndex,
                  items: playQueue.items.map { $0.persistentModelID })
    }
}

extension ListeningRoomPlaybackState {
    fileprivate static func from(_ playbackState: AudioPlayer.PlaybackState) -> Self {
        switch playbackState {
        case .playing:
            return .playing
        case .paused:
            return .paused
        case .stopped:
            return .stopped
        @unknown default:
            fatalError()
        }
    }
}
