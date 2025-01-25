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

enum SongsDestination: Hashable, Codable {
    case all
    case forArtist(PersistentIdentifier)
    case forAlbum(PersistentIdentifier)
    
    var filter: Predicate<Song>? {
        switch self {
        case .all:
            return nil
        case .forArtist(let artistID):
            return #Predicate<Song> { $0.artist?.persistentModelID == artistID }
        case .forAlbum(let albumID):
            return #Predicate<Song> { $0.album?.persistentModelID == albumID }
        }
    }
}
