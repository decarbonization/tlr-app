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
import SwiftData

@Model final class Song {
    struct Flags: OptionSet, Codable, CustomDebugStringConvertible {
        var rawValue: UInt
        
        static let disabled = Self(rawValue: 1 << 0)
        static let skipWhenShuffling = Self(rawValue: 1 << 1)
        static let fromCueSheet = Self(rawValue: 1 << 2)
        
        var debugDescription: String {
            var fields = [String]()
            if contains(.disabled) {
                fields.append(".disabled")
            }
            if contains(.skipWhenShuffling) {
                fields.append(".skipWhenShuffling")
            }
            if contains(.fromCueSheet) {
                fields.append(".fromCueSheet")
            }
            return "Flags(\(fields))"
        }
    }
    
    init(fileBookmark: Data,
         startTime: TimeInterval = 0,
         endTime: TimeInterval,
         flags: Flags = []) {
        self.fileBookmark = fileBookmark
        self.startTime = startTime
        self.endTime = endTime
        self.flags = flags
    }
    
    var fileBookmark: Data
    var fileURL: URL {
        get throws {
            var isStale = false
            return try URL(resolvingBookmarkData: fileBookmark,
                           options: [.withSecurityScope],
                           bookmarkDataIsStale: &isStale)
        }
    }
    var startTime: TimeInterval
    var endTime: TimeInterval
    var flags: Flags
    
    @Relationship var artist: Artist?
    @Relationship var album: Album?
    
    var title: String?
    var composer: String?
    var genre: String?
    var releaseDate: String?
    var trackNumber: UInt64?
    var trackTotal: UInt64?
    var discNumber: UInt64?
    var discTotal: UInt64?
    var lyrics: String?
    var bpm: UInt64?
    var comment: String?
}
