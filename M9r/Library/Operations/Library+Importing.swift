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
@preconcurrency import class Foundation.NSItemProvider

extension Library {
    @discardableResult func addSongs(fromContentsOf fileResults: [Result<URL, any Error>],
                                     reportingTo tasks: Tasks) -> [Result<Song, any Error>] {
        let progress = Progress(totalUnitCount: Int64(fileResults.count))
        progress.localizedDescription = NSLocalizedString("Importing Songs…", comment: "")
        tasks.add(progress)
        defer {
            tasks.remove(progress)
        }
        var songs = [Result<Song, any Error>]()
        songs.reserveCapacity(fileResults.count)
        for fileResult in fileResults {
            switch fileResult {
            case .success(let fileURL):
                progress.localizedAdditionalDescription = fileURL.lastPathComponent
                let song = Result {
                    try addSong(fileURL)
                }
                Library.log.debug("Imported \(fileURL): \(String(describing: song))")
                songs.append(song)
            case .failure(let error):
                songs.append(.failure(error))
            }
            progress.completedUnitCount += 1
        }
        return songs
    }
}
