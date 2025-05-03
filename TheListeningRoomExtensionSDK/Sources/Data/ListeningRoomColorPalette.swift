/*
 * MIT No Attribution
 *
 * Copyright 2025 Peter "Kevin" Contreras
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

private import CoreImage
private import CoreImage.CIFilterBuiltins
import Foundation

public struct ListeningRoomColorPalette: Hashable, Codable, Sendable {
    public enum AnalysisError: LocalizedError {
        case invalidData
        case kMeansFailure
        
        public var errorDescription: String? {
            switch self {
            case .invalidData:
                return "Data does not contain a valid image"
            case .kMeansFailure:
                return "K-means filter did not produce output"
            }
        }
    }
    
    public init(analyze imageData: Data) async throws {
        let colors = try await Task.detached {
            guard let image = CIImage(data: imageData) else {
                throw AnalysisError.invalidData
            }
            
            let kMeansFilter = CIFilter.kMeans()
            kMeansFilter.extent = image.extent
            kMeansFilter.count = 4
            kMeansFilter.passes = 5
            kMeansFilter.perceptual = true
            kMeansFilter.inputImage = image
            
            guard let rawOutputImage = kMeansFilter.outputImage else {
                throw AnalysisError.kMeansFailure
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
            
            var colors = [ListeningRoomColor]()
            for x in 0 ..< outputWidth {
                for y in 0 ..< outputHeight {
                    let i = (x * 4) + (y * outputWidth)
                    colors.append(ListeningRoomColor(red: Double(bitmap[i + 0]) / 255,
                                                     green: Double(bitmap[i + 1]) / 255,
                                                     blue: Double(bitmap[i + 2]) / 255,
                                                     alpha: Double(bitmap[i + 3]) / 255))
                }
            }
            return colors
        }.value
        self.init(background: colors[0],
                  primary: colors[1],
                  secondary: colors[2],
                  tertiary: colors[3])
    }
    
    public init(background: ListeningRoomColor,
                primary: ListeningRoomColor,
                secondary: ListeningRoomColor,
                tertiary: ListeningRoomColor) {
        self.background = background
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
    }
    
    public var background: ListeningRoomColor
    public var primary: ListeningRoomColor
    public var secondary: ListeningRoomColor
    public var tertiary: ListeningRoomColor
}
