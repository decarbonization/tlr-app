/*
 * M9r
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

func loadItemURLs(_ itemProviders: [NSItemProvider]) async throws -> [URL] {
    try await Progress.begin {
        let progress = Progress(totalUnitCount: Int64(itemProviders.count))
        progress.localizedDescription = NSLocalizedString("Loading…", comment: "")
        return progress
    } task: { progress in
        Task(priority: .userInitiated) {
            try await withThrowingTaskGroup(of: URL.self) { group in
                for itemProvider in itemProviders {
                    group.addTask {
                        try await withUnsafeThrowingContinuation { continuation in
                            let loadProgress = itemProvider.loadTransferable(type: URL.self) { result in
                                continuation.resume(with: result)
                            }
                            progress.addChild(loadProgress, withPendingUnitCount: 1)
                        }
                    }
                }
                var urls = [URL]()
                for try await url in group {
                    urls.append(url)
                }
                return urls
            }
        }
    }.value
}
