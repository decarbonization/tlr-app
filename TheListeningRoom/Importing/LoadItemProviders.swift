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
import CoreTransferable
import Foundation
import os

@MainActor func loadAll<T: Transferable>(_ transferableType: T.Type = T.self,
                                         from itemProviders: [NSItemProvider]) async -> [Result<T, any Error>] {
    await withUnsafeContinuation { continuation in
        let loadingNotification = ListeningRoomNotification(id: .unique,
                                                            title: NSLocalizedString("Loading…", comment: ""),
                                                            progress: .determinate(totalUnitCount: UInt64(itemProviders.count), completedUnitCount: 0))
        AppNotificationCenter.global.present(loadingNotification)
        let group = DispatchGroup()
        let results = OSAllocatedUnfairLock(initialState: [Result<T, any Error>]())
        for itemProvider in itemProviders {
            group.enter()
            _ = itemProvider.loadTransferable(type: transferableType) { result in
                loadingNotification.progress?.advance()
                results.withLock { results in
                    results.append(result)
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            AppNotificationCenter.global.dismiss(loadingNotification.id)
            continuation.resume(returning: results.withLock { $0 })
        }
    }
}
