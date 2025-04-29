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
import MediaPlayer
import SwiftUI
import SwiftData

extension ListeningRoomImage {
    @MainActor func image(in modelContext: ModelContext) -> Image? {
        switch self {
        case .systemImage(let name):
            return Image(systemName: name)
        case .artwork(let artworkID):
            guard let artwork = modelContext.model(for: artworkID) as? Artwork else {
                return nil
            }
            return artwork.image
        }
    }
    
    func mpMediaItemArtwork(in modelContext: ModelContext) -> MPMediaItemArtwork? {
        switch self {
        case .systemImage(let name):
            guard let symbolImage = NSImage(systemSymbolName: name, accessibilityDescription: nil) else {
                return nil
            }
            return MPMediaItemArtwork(boundsSize: symbolImage.size) { size in
                let image = symbolImage.copy() as! NSImage
                image.size = size
                return image
            }
        case .artwork(let artworkID):
            guard let artwork = modelContext.model(for: artworkID) as? Artwork else {
                return nil
            }
            guard let artworkImage = NSImage(data: artwork.payload) else {
                return nil
            }
            return MPMediaItemArtwork(boundsSize: artworkImage.size) { size in
                let image = artworkImage.copy() as! NSImage
                image.size = size
                return image
            }
        }
    }
}
