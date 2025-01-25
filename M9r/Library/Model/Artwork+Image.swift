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


import AppKit
import Foundation
import SwiftUI

extension Artwork {
    @MainActor private static var cachedNSImages: [String: Image] = [:]
    
    @MainActor var image: Image? {
        if let existingImage = Self.cachedNSImages[imageHash] {
            return existingImage
        } else {
            guard let nsImage = NSImage(data: imageData) else {
                return nil
            }
            let newImage = Image(nsImage: nsImage)
            Self.cachedNSImages[imageHash] = newImage
            return newImage
        }
    }
}
