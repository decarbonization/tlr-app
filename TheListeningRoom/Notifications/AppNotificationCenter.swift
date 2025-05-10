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
import TheListeningRoomExtensionSDK

@Observable final class AppNotificationCenter: ListeningRoomNotificationCenter {
    private struct State {
        var presented = [ListeningRoomNotification.ID: ListeningRoomNotification]()
        var ordering = [ListeningRoomNotification.ID]()
    }
    
    static let global = AppNotificationCenter()
    
    init() {
        _state = .init(initialState: State())
    }
    
    private let _state: OSAllocatedUnfairLock<State>
    
    var presented: [ListeningRoomNotification] {
        access(keyPath: \.presented)
        return _state.withLock { state in
            state.ordering.compactMap { state.presented[$0] }
        }
    }
    
    @MainActor func present(_ notification: ListeningRoomNotification) {
        withMutation(keyPath: \.presented) {
            _state.withLock { state in
                let needsToAddOrdering = state.presented[notification.id] == nil
                state.presented[notification.id] = notification
                if needsToAddOrdering {
                    state.ordering.append(notification.id)
                }
            }
        }
    }
    
    @MainActor func dismiss(_ notificationID: ListeningRoomNotification.ID) {
        withMutation(keyPath: \.presented) {
            _state.withLock { state in
                if state.presented.removeValue(forKey: notificationID) != nil {
                    guard let toRemove = state.ordering.firstIndex(of: notificationID) else {
                        return
                    }
                    state.ordering.remove(at: toRemove)
                }
            }
        }
    }
}

struct AppNotificationCenterAction: ListeningRoomXPCEndpoint {
    init(center: AppNotificationCenter) {
        self.center = center
    }
    
    private let center: AppNotificationCenter
    
    func callAsFunction(_ request: ListeningRoomHostNotificationCenterAction) async throws -> Nothing {
        switch request {
        case .present(let notification):
            center.present(notification)
        case .dismiss(let notificationID):
            center.dismiss(notificationID)
        }
        return .nothing
    }
}
