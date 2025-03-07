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

import CoreGraphics
import Foundation

struct RGBColor: Equatable, Codable {
    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    init?(cgColor: CGColor) {
        guard let srgbColorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let cgColor = cgColor.converted(to: srgbColorSpace, intent: .defaultIntent, options: nil),
              cgColor.numberOfComponents == 4,
              let components = cgColor.components else {
            return nil
        }
        self.init(red: components[0],
                  green: components[1],
                  blue: components[2],
                  alpha: cgColor.alpha)
    }
    
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    var cgColor: CGColor {
        CGColor(red: red,
                green: green,
                blue: blue,
                alpha: alpha)
    }
}
