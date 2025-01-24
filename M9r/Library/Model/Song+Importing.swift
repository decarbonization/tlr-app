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
import SwiftData

extension Song {
    convenience init(importing fileURL: URL) throws {
        let audioFile = try AudioFile(url: fileURL)
        try audioFile.readPropertiesAndMetadata()
        let audioFileMetadata = audioFile.metadata
        
        let fileBookmark = try fileURL.bookmarkData(options: [.withSecurityScope])
        self.init(fileBookmark: fileBookmark,
                  startTime: 0.0,
                  endTime: audioFile.properties.duration ?? 0.0)
        title = audioFileMetadata.title ?? fileURL.lastPathComponent
        artist = audioFileMetadata.artist
        album = audioFileMetadata.albumTitle
        genre = audioFileMetadata.genre
        releaseDate = audioFileMetadata.releaseDate
        trackNumber = audioFileMetadata.trackNumber.map(UInt64.init(clamping:))
        trackTotal = audioFileMetadata.trackTotal.map(UInt64.init(clamping:))
        discNumber = audioFileMetadata.discNumber.map(UInt64.init(clamping:))
        discTotal = audioFileMetadata.discTotal.map(UInt64.init(clamping:))
        lyrics = audioFileMetadata.lyrics
        bpm = audioFileMetadata.bpm.map(UInt64.init(clamping:))
        comment = audioFileMetadata.comment
    }
}
