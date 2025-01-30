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

extension Library {
    func deleteSongs(withIDs ids: Set<PersistentIdentifier>) throws {
        let whatSongs = FetchDescriptor<Song>(predicate: #Predicate { ids.contains($0.persistentModelID) })
        let toDelete = try modelContext.fetch(whatSongs)
        for song in toDelete {
            song.album = nil
            song.artist = nil
            song.artwork = []
            modelContext.delete(song)
        }
    }
    
    @discardableResult func addSong(_ fileURL: URL) throws -> Song {
        let audioFile = try AudioFile(url: fileURL)
        try audioFile.readPropertiesAndMetadata()
        
        let fileBookmark = try fileURL.bookmarkData(options: [.withSecurityScope])
        let newSong = Song(fileBookmark: fileBookmark,
                           startTime: 0.0,
                           endTime: audioFile.properties.duration ?? 0.0,
                           flags: [])
        try copy(audioFile.metadata,
                 from: fileURL,
                 to: newSong)
        modelContext.insert(newSong)
        Library.log.debug("Inserted \(fileURL): \(String(describing: newSong))")
        return newSong
    }
    
    func copy(_ metadata: AudioMetadata,
               from fileURL: URL,
               to song: Song) throws {
        if let title = song.title, !title.isEmpty {
            song.title = metadata.title
        } else {
            song.title = fileURL.lastPathComponent
        }
        if let artistName = metadata.artist {
            song.artist = try getOrInsertArtist(named: artistName)
        }
        if let albumTitle = metadata.albumTitle {
            song.album = try getOrInsertAlbum(named: albumTitle, by: metadata.artist)
        }
        song.artwork = try metadata.attachedPictures.compactMap {
            try getOrInsertArtwork(copying: $0)
        }
        song.genre = metadata.genre
        song.releaseDate = metadata.releaseDate
        song.trackNumber = metadata.trackNumber.map(UInt64.init(clamping:))
        song.trackTotal = metadata.trackTotal.map(UInt64.init(clamping:))
        song.discNumber = metadata.discNumber.map(UInt64.init(clamping:))
        song.discTotal = metadata.discTotal.map(UInt64.init(clamping:))
        song.lyrics = metadata.lyrics
        song.bpm = metadata.bpm.map(UInt64.init(clamping:))
        song.comment = metadata.comment
    }
}
