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

// Loosely based on <https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/manifest.json>.

extension WebExtension {
    enum ManifestVersion: UInt8, Codable {
        case v0 = 0
    }
    
    struct Developer: Codable {
        var name: String?
        var url: String?
    }
    
    struct Permission: RawRepresentable, Hashable, Codable {
        init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            rawValue = try container.decode(String.self)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
        
        var rawValue: String
        
        var displayName: String {
            switch self {
            case .networking:
                return NSLocalizedString("Networking", comment: "")
            case .playQueue:
                return NSLocalizedString("Play Queue", comment: "")
            default:
                return rawValue
            }
        }
        
        static let networking = Self(rawValue: "networking")
        static let playQueue = Self(rawValue: "playQueue")
    }
    
    struct SidebarAction: Codable {
        var defaultTitle: String?
        var defaultPanel: String
    }
    
    struct Manifest: Codable {
        static var jsonDecoder: JSONDecoder {
            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            jsonDecoder.dataDecodingStrategy = .base64
            jsonDecoder.dateDecodingStrategy = .iso8601
            jsonDecoder.allowsJSON5 = true
            return jsonDecoder
        }
        
        static var jsonEncoder: JSONEncoder {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
            jsonEncoder.dataEncodingStrategy = .base64
            jsonEncoder.dateEncodingStrategy = .iso8601
            return jsonEncoder
        }
        
        var manifestVersion: ManifestVersion
        var name: String
        var shortName: String?
        var description: String?
        var developer: Developer?
        var homepageUrl: String?
        var icons: [String: String]?
        var permissions: [Permission]?
        var version: String
        var versionName: String?
        var sidebarAction: SidebarAction?
    }
}
