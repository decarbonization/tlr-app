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
    func deleteArtists(withIDs ids: Set<PersistentIdentifier>) throws {
        let whatArtists = FetchDescriptor<Artist>(predicate: #Predicate { ids.contains($0.persistentModelID) })
        let toDelete = try modelContext.fetch(whatArtists)
        for artist in toDelete {
            artist.albums = []
            artist.songs = []
            modelContext.delete(artist)
        }
    }
    
    func getOrInsertArtist(named artistName: String) throws -> Artist {
        try getOrInsert(matching: #Predicate { $0.name == artistName }) {
            Artist(name: artistName)
        }
    }
}
