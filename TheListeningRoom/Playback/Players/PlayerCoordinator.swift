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
import os

@Observable final class PlayerCoordinator: Sendable {
    static let shared = PlayerCoordinator()
    
    private init() {
        _activePlayer = .init(initialState: nil)
    }
    
    private let _activePlayer: OSAllocatedUnfairLock<(any Player)?>
    
    var activePlayer: (any Player)? {
        access(keyPath: \.activePlayer)
        return _activePlayer.withLock { $0 }
    }
    
    @discardableResult func changeActivePlayer(_ newPlayer: (any Player)?) async throws -> (any Player)? {
        let oldPlayer = withMutation(keyPath: \.activePlayer) {
            _activePlayer.withLock { activePlayer in
                let oldPlayer = activePlayer
                activePlayer = newPlayer
                return oldPlayer
            }
        }
        try await oldPlayer?.pause()
        return oldPlayer
    }
}
