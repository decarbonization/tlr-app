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
import SFBAudioEngine

@ImportActor func findAudioFiles(fromContentsOf itemResults: [Result<URL, any Error>]) async -> [Result<URL, any Error>] {
    let discoveringNotification = ListeningRoomNotification(id: .unique,
                                                            title: NSLocalizedString("Discovering…", comment: ""),
                                                            progress: .determinate(totalUnitCount: UInt64(itemResults.count), completedUnitCount: 0))
    await AppNotificationCenter.global.present(discoveringNotification)
    var fileResults = [Result<URL, any Error>]()
    for itemResult in itemResults {
        defer {
            discoveringNotification.progress?.advance()
        }
        switch itemResult {
        case .success(let url):
            discoveringNotification.details = url.lastPathComponent
            fileResults.append(contentsOf: findAudioFiles(at: url))
        case .failure(let error):
            discoveringNotification.details = error.localizedDescription
            fileResults.append(.failure(error))
        }
    }
    await AppNotificationCenter.global.dismiss(discoveringNotification.id)
    return fileResults
}

func findAudioFiles(at url: URL) -> [Result<URL, any Error>] {
    guard url.isFileURL else {
        return [.failure(URLError(.badURL,
                                  userInfo: [NSLocalizedDescriptionKey: "Cannot load non-file URL <\(url)>",
                                                         NSURLErrorKey: url]))]
    }
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) else {
        return [.failure(CocoaError(.fileNoSuchFile,
                                    userInfo: [NSLocalizedDescriptionKey: "No file found at <\(url)>",
                                                           NSURLErrorKey: url]))]
    }
    guard isDirectory.boolValue else {
        return [.success(url)]
    }
    guard let enumerator = FileManager.default.enumerator(at: url,
                                                          includingPropertiesForKeys: [.isDirectoryKey],
                                                          options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
        return [.failure(CocoaError(.fileReadNoPermission,
                                    userInfo: [NSLocalizedDescriptionKey: "Could not access <\(url)>",
                                                           NSURLErrorKey: url]))]
    }
    return [Result<URL, any Error>](
        enumerator.lazy
            .compactMap { $0 as? URL }
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory != true }
            .map { fileURL in
                do {
                    return withExtendedLifetime(try AudioDecoder(url: fileURL, detectContentType: true)) {
                        .success(fileURL)
                    }
                } catch {
                    return .failure(error)
                }
            }
    )
}
