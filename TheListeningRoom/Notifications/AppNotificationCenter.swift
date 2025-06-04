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

@Observable @MainActor final class AppNotificationCenter: ListeningRoomNotificationCenter {
    private struct State {
        
    }
    
    static let global = AppNotificationCenter()
    
    init() {
    }
    
    private var presentedByID = [ListeningRoomNotification.ID: ListeningRoomNotification]()
    private var presentationOrder = [ListeningRoomNotification.ID]()
    
    var presented: [ListeningRoomNotification] {
        access(keyPath: \.presented)
        return presentationOrder.compactMap { presentedByID[$0] }
    }
    
    @MainActor func present(_ notification: ListeningRoomNotification) {
        withMutation(keyPath: \.presented) {
            let needsToAddOrdering = presentedByID[notification.id] == nil
            presentedByID[notification.id] = notification
            if needsToAddOrdering {
                presentationOrder.append(notification.id)
            }
        }
    }
    
    @MainActor func dismiss(_ notificationID: ListeningRoomNotification.ID) {
        withMutation(keyPath: \.presented) {
            if presentedByID.removeValue(forKey: notificationID) != nil {
                guard let toRemove = presentationOrder.firstIndex(of: notificationID) else {
                    return
                }
                presentationOrder.remove(at: toRemove)
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
