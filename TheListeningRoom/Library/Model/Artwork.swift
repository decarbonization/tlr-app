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

import TheListeningRoomExtensionSDK
import CryptoKit
import Foundation
import SwiftData

typealias Artwork = LatestAppSchema.Artwork

extension AppSchemaV0 {
    @Model final class Artwork: ExtensionAccessibleModel, TimeStamped {
        #Index([\Artwork.payloadHash], [\Artwork.extensionID])
        #Unique([\Artwork.payloadHash], [\Artwork.extensionID])
        
        static let extensionEntity = ListeningRoomID.Entity.artwork
        
        enum Kind: UInt64, Codable {
            // TODO: Support more kinds
            case frontCover
        }
        
        enum PayloadType: UInt64, Codable {
            case data
        }
        
        static func hash(for imageData: Data) -> String {
            var sha256 = SHA256()
            sha256.update(data: imageData)
            let digest = sha256.finalize()
            return digest.description
        }
        
        init(kind: Kind = .frontCover,
             payloadHash: String,
             payloadType: PayloadType,
             payload: Data,
             songs: [Song] = [],
             colorPalette: ListeningRoomColorPalette? = nil) {
            self.extensionID = Self.nextExtensionID
            self.creationDate = Date()
            self.lastModified = Date()
            self.kind = kind
            self.payloadHash = payloadHash
            self.payloadType = payloadType
            self.payload = payload
            self.songs = songs
            self.colorPalette = nil
        }
        
        private(set) var extensionID: String
        private(set) var creationDate: Date
        var lastModified: Date
        
        var kind: Kind
        var payloadHash: String
        var payloadType: PayloadType
        var payload: Data
        var colorPalette: ListeningRoomColorPalette?
        @Relationship(inverse: \Song.artwork) var songs: [Song]
    }
}
