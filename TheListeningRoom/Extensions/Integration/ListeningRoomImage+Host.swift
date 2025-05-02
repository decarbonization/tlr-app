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
import CoreImage
import CoreImage.CIFilterBuiltins
import MediaPlayer
import SwiftUI
import SwiftData

extension ListeningRoomImage {
    @MainActor func image(in modelContext: ModelContext) -> Image? {
        switch self {
        case .image(let nsImage):
            return Image(nsImage: nsImage)
        case .artwork(let artworkID):
            guard let artwork = modelContext.model(for: artworkID) as? Artwork else {
                return nil
            }
            return artwork.image
        }
    }
    
    func mpMediaItemArtwork(in modelContext: ModelContext) -> MPMediaItemArtwork? {
        switch self {
        case .image(let nsImage):
            return MPMediaItemArtwork(boundsSize: nsImage.size) { size in
                let image = nsImage.copy() as! NSImage
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
    
    @MainActor func ciImage(in modelContext: ModelContext) -> CIImage? {
        switch self {
        case .image(let nsImage):
            guard let imageData = nsImage.tiffRepresentation else {
                return nil
            }
            return CIImage(data: imageData)
        case .artwork(let artworkID):
            guard let artwork = modelContext.model(for: artworkID) as? Artwork else {
                return nil
            }
            switch artwork.payloadType {
            case .data:
                return CIImage(data: artwork.payload)
            }
        }
    }
    
    @MainActor func predominantColors(in modelContext: ModelContext) async -> [RGBColor]? {
        guard let image = ciImage(in: modelContext) else {
            return nil
        }
        let kMeansFilter = CIFilter.kMeans()
        kMeansFilter.extent = image.extent
        kMeansFilter.count = 4
        kMeansFilter.passes = 5
        kMeansFilter.perceptual = true
        kMeansFilter.inputImage = image

        guard let rawOutputImage = kMeansFilter.outputImage else {
            return nil
        }
        let outputImage = rawOutputImage.settingAlphaOne(in: rawOutputImage.extent)
        let outputWidth = Int(outputImage.extent.width)
        let outputHeight = Int(outputImage.extent.height)
        
        let context = CIContext()
        var bitmap = [UInt8](repeating: 0, count: 4 * outputWidth * outputHeight)
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: bitmap.count,
                       bounds: outputImage.extent,
                       format: .RGBA8,
                       colorSpace: outputImage.colorSpace)

        var colors = [RGBColor]()
        for x in 0 ..< outputWidth {
            for y in 0 ..< outputHeight {
                let i = (x * 4) + (y * outputWidth)
                colors.append(RGBColor(red: Double(bitmap[i + 0]) / 255,
                                       green: Double(bitmap[i + 1]) / 255,
                                       blue: Double(bitmap[i + 2]) / 255,
                                       alpha: Double(bitmap[i + 3]) / 255))
            }
        }
        return colors
    }
}
