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

import Foundation
import SwiftData

extension Library {
    func deleteAlbums(withIDs ids: Set<PersistentIdentifier>) throws {
        let whatAlbums = FetchDescriptor<Album>(predicate: #Predicate { ids.contains($0.persistentModelID) })
        let toDelete = try modelContext.fetch(whatAlbums)
        for album in toDelete {
            album.artist = nil
            album.songs = []
            modelContext.delete(album)
        }
    }
    
    func getOrInsertAlbum(named albumTitle: String,
                          by artistName: String?) throws -> Album {
        try getOrInsert(matching: #Predicate { $0.title == albumTitle }) {
            Album(title: albumTitle,
                  artist: try artistName.map { try getOrInsertArtist(named: $0) })
        }
    }
}
