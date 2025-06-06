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

import SwiftUI
import TheListeningRoomExtensionSDK

struct NotificationList: View {
    var body: some View {
        let notifications = AppNotificationCenter.global.presented
        if notifications.isEmpty {
            NoContentView("No Notifications")
        } else {
            List(notifications) { notification in
                NotificationView(notification: notification)
            }
            .listStyle(.plain)
        }
    }
}
