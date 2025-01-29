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

extension Library {
    func getOrInsertArtwork(copying picture: AttachedPicture) throws -> Artwork? {
        guard picture.type == .frontCover else {
            // TODO: Support other kinds of artwork
            return nil
        }
        let imageHash = Artwork.imageHash(for: picture.imageData)
        return try getOrInsert(matching: #Predicate { $0.imageHash == imageHash }) {
            Artwork(imageHash: imageHash,
                    imageData: picture.imageData)
        }
    }
}
