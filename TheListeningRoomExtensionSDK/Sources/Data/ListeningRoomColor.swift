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

import CoreGraphics
import Foundation
import SwiftUI

public struct ListeningRoomColor: Hashable, Codable, Sendable {
    public init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public init?(cgColor: CGColor) {
        guard let sListeningRoomColorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let cgColor = cgColor.converted(to: sListeningRoomColorSpace, intent: .defaultIntent, options: nil),
              cgColor.numberOfComponents == 4,
              let components = cgColor.components else {
            return nil
        }
        self.init(red: components[0],
                  green: components[1],
                  blue: components[2],
                  alpha: cgColor.alpha)
    }
    
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double
    
    public var cgColor: CGColor {
        CGColor(red: red,
                green: green,
                blue: blue,
                alpha: alpha)
    }
}
