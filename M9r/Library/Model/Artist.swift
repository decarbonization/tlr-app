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

import SwiftData

@Model final class Artist {
    init(name: String,
         albums: [Album] = [],
         songs: [Song] = []) {
        self.name = name
        self.albums = albums
        self.songs = songs
    }
    
    var name: String
    @Relationship(inverse: \Album.artist) var albums: [Album]
    @Relationship(inverse: \Song.artist) var songs: [Song]
}
