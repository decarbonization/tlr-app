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
    init(fileBookmark: Data,
         startTime: TimeInterval,
         endTime: TimeInterval) {
        self.fileBookmark = fileBookmark
        self.startTime = startTime
        self.endTime = endTime
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
