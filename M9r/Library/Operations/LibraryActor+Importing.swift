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
    func addOrGetAlbum(_ albumName: String,
                       by artistName: String?) throws -> Album {
        var whatAlbum = FetchDescriptor<Album>(predicate: #Predicate { $0.name == albumName })
        whatAlbum.fetchLimit = 1
        whatAlbum.includePendingChanges = true
        let existingAlbum = try modelContext.fetch(whatAlbum)
        if existingAlbum.count == 1 {
            return existingAlbum[0]
        } else {
            let artist = try artistName.map { try addOrGetArtist($0) }
            let newAlbum = Album(name: albumName,
                                 artist: artist)
            modelContext.insert(newAlbum)
            return newAlbum
        }
    }
    
    func addOrGetArtist(_ artistName: String) throws -> Artist {
        var whatArtist = FetchDescriptor<Artist>(predicate: #Predicate { $0.name == artistName })
        whatArtist.fetchLimit = 1
        whatArtist.includePendingChanges = true
        let existingArtist = try modelContext.fetch(whatArtist)
        if existingArtist.count == 1 {
            return existingArtist[0]
        } else {
            let newArtist = Artist(name: artistName)
            modelContext.insert(newArtist)
            return newArtist
        }
    }
    
    func addOrGetArtwork(_ picture: AttachedPicture) throws -> Artwork? {
        guard picture.type == .frontCover else {
            // TODO: Support other kinds of artwork
            return nil
        }
        let imageHash = Artwork.imageHash(for: picture.imageData)
        var whatArtwork = FetchDescriptor<Artwork>(predicate: #Predicate { $0.imageHash == imageHash })
        whatArtwork.fetchLimit = 1
        whatArtwork.includePendingChanges = true
        let existingArtwork = try modelContext.fetch(whatArtwork)
        if existingArtwork.count == 1 {
            return existingArtwork[0]
        } else {
            let newArtwork = Artwork(imageHash: imageHash,
                                     imageData: picture.imageData)
            modelContext.insert(newArtwork)
            return newArtwork
        }
    }
    
    func addSong(_ fileURL: URL) throws -> Song {
        let audioFile = try AudioFile(url: fileURL)
        try audioFile.readPropertiesAndMetadata()
        let audioFileMetadata = audioFile.metadata
        
        let fileBookmark = try fileURL.bookmarkData(options: [.withSecurityScope])
        let newSong = Song(fileBookmark: fileBookmark,
                           startTime: 0.0,
                           endTime: audioFile.properties.duration ?? 0.0,
                           flags: [])
        newSong.title = audioFileMetadata.title ?? fileURL.lastPathComponent
        if let artistName = audioFileMetadata.artist {
            newSong.artist = try addOrGetArtist(artistName)
        }
        if let albumTitle = audioFileMetadata.albumTitle {
            newSong.album = try addOrGetAlbum(albumTitle, by: audioFileMetadata.artist)
        }
        newSong.artwork = try audioFileMetadata.attachedPictures.compactMap {
            try addOrGetArtwork($0)
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
        return newSong
    }
}
