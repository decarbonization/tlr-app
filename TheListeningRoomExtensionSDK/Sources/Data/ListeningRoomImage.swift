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

import Foundation
import SwiftData
import SwiftUI

public enum ListeningRoomImage: Codable, @unchecked /* NSImage */ Sendable {
    case image(NSImage)
    case artwork(id: ListeningRoomID)
    
    public static func systemImage(_ name: String) -> Self {
        .image(NSImage(systemSymbolName: name, accessibilityDescription: nil) ?? NSImage())
    }
    
    private enum CodingKeys: String, CodingKey {
        case image
        case artwork
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let imageData = try container.decodeIfPresent(Data.self, forKey: .image) {
            guard let nsImage = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSImage.self, from: imageData) else {
                throw DecodingError.keyNotFound(CodingKeys.image, DecodingError.Context(codingPath: decoder.codingPath,
                                                                                        debugDescription: "Image corrupt"))
            }
            self = .image(nsImage)
        } else if let id = try container.decodeIfPresent(ListeningRoomID.self, forKey: .artwork) {
            self = .artwork(id: id)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                    debugDescription: "Unknown image case"))
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .image(let nsImage):
            let imageData = try NSKeyedArchiver.archivedData(withRootObject: nsImage,
                                                             requiringSecureCoding: true)
            try container.encode(imageData, forKey: .image)
        case .artwork(let id):
            try container.encode(id, forKey: .artwork)
        }
    }
}
