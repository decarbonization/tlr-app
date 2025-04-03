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
import MediaPlayer
import SwiftData

public struct ListeningRoomPlayingItem: Identifiable, Codable, Sendable {
    public enum Kind: Codable, Sendable {
        case song
        
        public var mpMediaType: MPMediaType {
            switch self {
            case .song:
                return .music
            }
        }
    }
    
    public init(id: PersistentIdentifier,
                kind: Kind,
                startTime: TimeInterval,
                endTime: TimeInterval,
                assetURL: URL,
                title: String? = nil,
                artist: String? = nil,
                albumTitle: String? = nil,
                albumArtist: String? = nil,
                composer: String? = nil,
                genre: String? = nil,
                isCompilation: Bool? = nil,
                releaseDate: String? = nil,
                trackNumber: UInt64? = nil,
                trackTotal: UInt64? = nil,
                discNumber: UInt64? = nil,
                discTotal: UInt64? = nil,
                lyrics: String? = nil,
                bpm: UInt64? = nil) {
        self.id = id
        self.kind = kind
        self.startTime = startTime
        self.endTime = endTime
        self.assetURL = assetURL
        self.title = title
        self.artist = artist
        self.albumTitle = albumTitle
        self.albumArtist = albumArtist
        self.composer = composer
        self.genre = genre
        self.isCompilation = isCompilation
        self.releaseDate = releaseDate
        self.trackNumber = trackNumber
        self.trackTotal = trackTotal
        self.discNumber = discNumber
        self.discTotal = discTotal
        self.lyrics = lyrics
        self.bpm = bpm
    }
    
    public var id: PersistentIdentifier
    public var kind: Kind
    public var startTime: TimeInterval
    public var endTime: TimeInterval
    public var assetURL: URL
    public var title: String?
    public var artist: String?
    public var albumTitle: String?
    public var albumArtist: String?
    public var composer: String?
    public var genre: String?
    public var isCompilation: Bool?
    public var releaseDate: String?
    public var trackNumber: UInt64?
    public var trackTotal: UInt64?
    public var discNumber: UInt64?
    public var discTotal: UInt64?
    public var lyrics: String?
    public var bpm: UInt64?
    
    public var mpItemProperties: [String: Any] {
        var properties = [String: Any]()
        properties[MPMediaItemPropertyMediaType] = kind.mpMediaType
        properties[MPMediaItemPropertyPlaybackDuration] = endTime - startTime
        properties[MPMediaItemPropertyAssetURL] = assetURL
        properties[MPMediaItemPropertyTitle] = title
        properties[MPMediaItemPropertyArtist] = artist
        properties[MPMediaItemPropertyAlbumTitle] = albumTitle
        properties[MPMediaItemPropertyAlbumArtist] = albumArtist
        properties[MPMediaItemPropertyComposer] = composer
        properties[MPMediaItemPropertyGenre] = genre
        properties[MPMediaItemPropertyIsCompilation] = isCompilation
        properties[MPMediaItemPropertyReleaseDate] = releaseDate
        properties[MPMediaItemPropertyAlbumTrackNumber] = trackNumber
        properties[MPMediaItemPropertyAlbumTrackCount] = trackTotal
        properties[MPMediaItemPropertyDiscNumber] = discNumber
        properties[MPMediaItemPropertyDiscCount] = discTotal
        properties[MPMediaItemPropertyLyrics] = lyrics
        properties[MPMediaItemPropertyBeatsPerMinute] = bpm
        return properties
    }
}
