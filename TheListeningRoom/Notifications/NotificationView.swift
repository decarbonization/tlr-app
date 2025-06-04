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

struct NotificationView: View {
    init(notification: ListeningRoomNotification) {
        self.notification = notification
    }
    
    private let notification: ListeningRoomNotification
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack {
            if let icon = notification.icon?.image(in: modelContext) {
                icon.resizable()
                    .frame(width: 48, height: 48)
            }
            VStack {
                Text(verbatim: notification.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let details = notification.details {
                    Text(verbatim: details)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let progress = notification.progress {
                    ProgressView(value: progress.fractionCompleted, total: 1.0)
                }
                ForEach(notification.actions) { action in
                    Button(action.title) {
                        // TODO: use role
                        // TODO: execute action
                    }
                }
            }
        }
    }
}
