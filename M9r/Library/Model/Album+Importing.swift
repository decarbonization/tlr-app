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
import SwiftData

extension Album {
    static func forName(_ albumName: String,
                        by artistName: String?,
                        in context: ModelContext) throws -> Album {
        var whatAlbum = FetchDescriptor<Album>(predicate: #Predicate { $0.name == albumName })
        whatAlbum.fetchLimit = 1
        whatAlbum.includePendingChanges = true
        let existingAlbum = try context.fetch(whatAlbum)
        if existingAlbum.count == 1 {
            return existingAlbum[0]
        } else {
            let artist = try artistName.map { try Artist.forName($0, in: context) }
            let newAlbum = Album(name: albumName,
                                 artist: artist)
            context.insert(newAlbum)
            return newAlbum
        }
    }
}
