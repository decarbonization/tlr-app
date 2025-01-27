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

import CryptoKit
import Foundation
import SwiftData

@Model final class Artwork {
    #Index([\Artwork.imageHash])
    #Unique([\Artwork.imageHash])
    
    enum Kind: UInt64, Codable {
        // TODO: Support more kinds
        case frontCover
    }
    
    static func imageHash(for imageData: Data) -> String {
        var sha256 = SHA256()
        sha256.update(data: imageData)
        let digest = sha256.finalize()
        return digest.description
    }
    
    init(kind: Kind = .frontCover,
         imageHash: String,
         imageData: Data,
         songs: [Song] = []) {
        self.kind = kind
        self.imageHash = imageHash
        self.imageData = imageData
        self.songs = songs
    }
    
    var kind: Kind
    var imageHash: String
    var imageData: Data // TODO: This should be stored outside the DB once the DB is persistent
    @Relationship(inverse: \Song.artwork) var songs: [Song]
}
