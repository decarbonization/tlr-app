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

extension LibraryActor {
    func addSongs(_ fileURLs: some Sequence<URL>) throws {
        for fileURL in fileURLs {
            let audioFile = try AudioFile(url: fileURL)
            try audioFile.readPropertiesAndMetadata()
            let audioFileMetadata = audioFile.metadata
            
            let fileBookmark = try fileURL.bookmarkData(options: [.withSecurityScope])
            let newSong = Song(fileBookmark: fileBookmark,
                               startTime: 0.0,
                               endTime: audioFile.properties.duration ?? 0.0)
            newSong.title = audioFileMetadata.title ?? fileURL.lastPathComponent
            if let artist = audioFileMetadata.artist {
                newSong.artist = try Artist.forName(artist, in: modelContext)
            }
            if let album = audioFileMetadata.albumTitle {
                newSong.album = try Album.forName(album,
                                                  by: audioFileMetadata.artist,
                                                  in: modelContext)
            }
            newSong.genre = audioFileMetadata.genre
            newSong.releaseDate = audioFileMetadata.releaseDate
            newSong.trackNumber = audioFileMetadata.trackNumber.map(UInt64.init(clamping:))
            newSong.trackTotal = audioFileMetadata.trackTotal.map(UInt64.init(clamping:))
            newSong.discNumber = audioFileMetadata.discNumber.map(UInt64.init(clamping:))
            newSong.discTotal = audioFileMetadata.discTotal.map(UInt64.init(clamping:))
            newSong.lyrics = audioFileMetadata.lyrics
            newSong.bpm = audioFileMetadata.bpm.map(UInt64.init(clamping:))
            newSong.comment = audioFileMetadata.comment
            modelContext.insert(newSong)
        }
        try modelContext.save()
    }
}
