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
    func addSongs(fromItems itemProvider: NSItemProvider) async {
        let loadResult = await withUnsafeContinuation { continuation in
            _ = itemProvider.loadTransferable(type: URL.self) { loadResult in
                continuation.resume(returning: loadResult)
            }
        }
        guard case .success(let itemURL) = loadResult else {
            return
        }
        let fileURLs = findAudioFiles(at: itemURL)
        addSongs(fromFilesAt: fileURLs)
    }
    
    @discardableResult func addSongs(fromFilesAt fileURLs: [URL]) -> [Result<Song, any Error>] {
        let progress = Progress(totalUnitCount: Int64(fileURLs.count))
        progress.localizedDescription = NSLocalizedString("Importing Songs…", comment: "")
        tasks.add(progress)
        defer {
            tasks.remove(progress)
        }
        var songs = [Result<Song, any Error>]()
        songs.reserveCapacity(fileURLs.count)
        for fileURL in fileURLs {
            progress.localizedAdditionalDescription = fileURL.lastPathComponent
            let song = Result {
                try addSong(fileURL)
            }
            Library.log.debug("Imported \(fileURL): \(String(describing: song))")
            songs.append(song)
            progress.completedUnitCount += 1
        }
        return songs
    }
}
