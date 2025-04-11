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
import SwiftUI
import SwiftData

extension ListeningRoomImage {
    @MainActor func image(in modelContext: ModelContext) -> Image? {
        switch self {
        case .systemImage(let name):
            return Image(systemName: name)
        case .artwork(let artworkID):
            guard let artwork: Artwork = modelContext.registeredModel(for: artworkID) else {
                return nil
            }
            return artwork.image
        }
    }
}
