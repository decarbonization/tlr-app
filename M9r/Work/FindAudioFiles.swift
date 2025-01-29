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
import SFBAudioEngine

func findAudioFiles(_ urls: [URL]) async throws -> [URL] {
    try await Progress.begin {
        let progress = Progress(totalUnitCount: Int64(urls.count))
        progress.localizedDescription = NSLocalizedString("Finding Audio Files…", comment: "")
        return progress
    } task: { progress in
        Task(priority: .background) {
            try await withThrowingTaskGroup(of: [URL].self) { group in
                for url in urls {
                    group.addTask {
                        try Task.checkCancellation()
                        progress.completedUnitCount += 1
                        guard url.isFileURL else {
                            return []
                        }
                        var isDirectory: ObjCBool = false
                        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) else {
                            return []
                        }
                        guard isDirectory.boolValue else {
                            return [url]
                        }
                        guard let enumerator = FileManager.default.enumerator(at: url,
                                                                              includingPropertiesForKeys: nil,
                                                                              options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
                            return []
                        }
                        return try enumerator.compactMap { next in
                            try Task.checkCancellation()
                            guard let nextURL = next as? URL else {
                                return nil
                            }
                            guard AudioDecoder.handlesPaths(withExtension: nextURL.pathExtension) else {
                                return nil
                            }
                            return nextURL
                        }
                    }
                }
                var allURLs = [URL]()
                for try await urls in group {
                    allURLs.append(contentsOf: urls)
                }
                return allURLs
            }
        }
    }.value
}
