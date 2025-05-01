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

struct PlayerStatePoster: ListeningRoomXPCPoster {
    init(_ player: Player) {
        self.player = player
    }
    
    private let player: Player
    
    func activate() -> some (AsyncSequence<ListeningRoomPlayerState, Never> & Sendable) {
        player.observeChanges(to: \.playbackState, \.playingItem)
            .map { _ in
                await ListeningRoomPlayerState(from: player)
            }
    }
}
