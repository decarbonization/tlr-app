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
import TheListeningRoomExtensionSDK

typealias Artist = LatestAppSchema.Artist

extension AppSchemaV0 {
    @Model final class Artist: ExternallyIdentifiable, SongCollection, TimeStamped {
        #Index([\Artist.name])
        #Unique([\Artist.name])
        
        static let externalEntity = ListeningRoomID.Entity.artist
        
        init(name: String,
             albums: [Album] = [],
             songs: [Song] = []) {
            self.externalID = Self.makeUniqueExternalID()
            self.creationDate = Date()
            self.lastModified = Date()
            self.name = name
            self.albums = albums
            self.songs = songs
        }
        
        private(set) var externalID: String
        private(set) var creationDate: Date
        var lastModified: Date
        
        var name: String
        @Relationship(inverse: \Album.artist) var albums: [Album]
        @Relationship(inverse: \Song.artist) var songs: [Song]
        
        var sortedSongs: [Song] {
            albums.sorted(using: KeyPathComparator(\.title))
                .reduce(into: [Song]()) { songs, album in
                    songs.append(contentsOf: album.sortedSongs)
                }
        }
    }
}
