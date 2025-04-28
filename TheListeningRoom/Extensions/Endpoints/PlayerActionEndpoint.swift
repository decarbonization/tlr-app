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
import SwiftData

struct PlayerActionEndpoint: ListeningRoomXPCEndpoint {
    init(_ player: Player) {
        self.player = player
    }
    
    private let player: Player
    
    func callAsFunction(_ action: ListeningRoomHostPlayerAction) async throws -> ListeningRoomPlayerStateChange {
        switch action {
        case .syncState:
            break // just return
        case .replaceQueue(let newItemsIDs, let nextItemID):
            player.queue.replace(withContentsOf: newItemsIDs, pinning: nextItemID)
        case .play(let itemID):
            try await player.playItem(withID: itemID)
        case .pause:
            try await player.pause()
        case .resume:
            try await player.resume()
        case .skipPrevious:
            try await player.skipPrevious()
        case .skipNext:
            try await player.skipNext()
        }
        return ListeningRoomPlayerStateChange(from: player)
    }
}

extension ListeningRoomPlayerStateChange {
    @MainActor init(from player: Player) {
        self.init(playbackState: player.playbackState,
                  playingItemIndex: player.playingIndex,
                  items: [PersistentIdentifier](player.queue.itemIDs))
    }
}

