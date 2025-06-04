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
@preconcurrency import class Foundation.NSItemProvider

extension Library {
    func findAndAddSongs(fromContentsOf urlResults: [Result<URL, any Error>]) async -> [Result<Song, any Error>] {
        let fileResults = await findAudioFiles(fromContentsOf: urlResults)
        
        let importingNotification = ListeningRoomNotification(id: .unique,
                                                                title: NSLocalizedString("Importing Songs…", comment: ""),
                                                                progress: .determinate(totalUnitCount: UInt64(fileResults.count), completedUnitCount: 0))
        await AppNotificationCenter.global.present(importingNotification)
        var addResults = [Result<Song, any Error>]()
        for fileResult in fileResults {
            defer {
                importingNotification.progress?.advance()
            }
            switch fileResult {
            case .success(let fileURL):
                importingNotification.details = fileURL.lastPathComponent
                do {
                    try addSong(fileURL)
                } catch {
                    Library.log.error("Could not import \(fileURL), reason: \(error)")
                    addResults.append(.failure(error))
                }
            case .failure(let error):
                importingNotification.details = error.localizedDescription
                addResults.append(.failure(error))
            }
        }
        await AppNotificationCenter.global.dismiss(importingNotification.id)
        return addResults
    }
}
