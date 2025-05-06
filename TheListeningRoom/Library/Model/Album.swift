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

typealias Album = LatestAppSchema.Album

extension AppSchemaV0 {
    @Model final class Album: ExtensionAccessibleModel, SongCollection, TimeStamped {
        #Index([\Album.title], [\Album.extensionID])
        #Unique([\Album.title], [\Album.extensionID])
        
        static let extensionEntity = ListeningRoomID.Entity.album
        
        init(title: String,
             artist: Artist? = nil,
             songs: [Song] = []) {
            self.extensionID = Self.nextExtensionID
            self.creationDate = Date()
            self.lastModified = Date()
            self.title = title
            self.artist = artist
            self.songs = songs
        }
        
        private(set) var extensionID: String
        private(set) var creationDate: Date
        var lastModified: Date
        
        var title: String
        @Relationship var artist: Artist?
        @Relationship(inverse: \Song.album) var songs: [Song]
        
        var sortedSongs: [Song] {
            songs.sorted(using: [
                KeyPathComparator(\.discNumber),
                KeyPathComparator(\.trackNumber),
            ])
        }
    }
}
