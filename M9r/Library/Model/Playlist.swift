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

typealias Playlist = LatestAppSchema.Playlist

extension AppSchemaV0 {
    @Model final class Playlist: SongCollection {
        init(name: String,
             userDescription: String? = nil,
             accentColor: RGBColor? = nil) {
            self.name = name
            self.userDescription = userDescription
            self.accentColor = accentColor
            self.songs = []
        }
        
        var name: String
        var userDescription: String?
        var accentColor: RGBColor?
        @Relationship(inverse: \Song.playlists) var songs: [Song]
        
        var sortedSongs: [Song] {
            songs // Already in user-defined order
        }
    }
}
