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

import Foundation
import SwiftData
import TheListeningRoomExtensionSDK

typealias Song = LatestAppSchema.Song

extension AppSchemaV0 {
    @Model final class Song: ExternallyIdentifiable, SongCollection, TimeStamped {
        #Index([\Song.externalID])
        
        struct Flags: OptionSet, Codable, CustomDebugStringConvertible {
            var rawValue: UInt
            
            static let disabled = Self(rawValue: 1 << 0)
            static let skipWhenShuffling = Self(rawValue: 1 << 1)
            static let compilation = Self(rawValue: 1 << 2)
            static let fromCueSheet = Self(rawValue: 1 << 3)
            
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
        
        static let externalEntity = ListeningRoomID.Entity.song
        
        init(url: URL,
             startTime: TimeInterval,
             endTime: TimeInterval) {
            self.externalID = Self.makeUniqueExternalID()
            self.creationDate = Date()
            self.lastModified = Date()
            self.url = url
            self.startTime = startTime
            self.endTime = endTime
            self.flags = []
            self.artwork = []
            self.playlistItems = []
        }
        
        private(set) var externalID: String
        private(set) var creationDate: Date
        var lastModified: Date
        var lastPlayed: Date?
        
        var url: URL
        var fileBookmark: Data?
        
        var startTime: TimeInterval
        var endTime: TimeInterval
        var flags: Flags
        var duration: Duration {
            Duration.seconds(endTime - startTime)
        }
        
        @Relationship var artist: Artist?
        @Relationship var album: Album?
        @Relationship var artwork: [Artwork]
        @Relationship var playlistItems: [PlaylistItem]
        
        var title: String?
        var albumArtist: String?
        var composer: String?
        var genre: String?
        var releaseDate: String?
        var trackNumber: UInt64?
        var trackTotal: UInt64?
        var discNumber: UInt64?
        var discTotal: UInt64?
        var lyrics: String?
        var rating: Float?
        var bpm: UInt64?
        var comment: String?
        var grouping: String?
        var mcn: String?
        var isrc: String?
        var musicBrainzReleaseID: String?
        var musicBrainzRecordingID: String?
        
        var sortedSongs: [Song] {
            [self]
        }
        
        var frontCoverArtwork: Artwork? {
            artwork.first(where: { $0.kind == .frontCover })
        }
        
        func currentURL(relativeTo libraryURL: URL? = nil) throws -> URL {
            // TODO: Try to repair stale/broken bookmarks
            guard let fileBookmark else {
                return url
            }
            var isStale = false
            return try URL(resolvingBookmarkData: fileBookmark,
                           options: [.withSecurityScope],
                           relativeTo: libraryURL,
                           bookmarkDataIsStale: &isStale)
        }
    }
}
