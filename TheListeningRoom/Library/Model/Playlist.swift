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
import Foundation
import SwiftData

typealias Playlist = LatestAppSchema.Playlist
typealias PlaylistItem = LatestAppSchema.PlaylistItem

extension AppSchemaV0 {
    @Model final class Playlist: ExternallyIdentifiable, SongCollection, TimeStamped {
        init(name: String,
             userDescription: String? = nil,
             accentColor: ListeningRoomColor? = nil) {
            self.externalID = Self.makeUniqueExternalID()
            self.creationDate = Date()
            self.lastModified = Date()
            self.name = name
            self.userDescription = userDescription
            self.accentColor = accentColor
            self.playlistItems = []
        }
        
        private(set) var externalID: String
        private(set) var creationDate: Date
        var lastModified: Date
        
        var name: String
        var userDescription: String?
        var accentColor: ListeningRoomColor?
        @Relationship(deleteRule: .cascade) var playlistItems: [PlaylistItem]
        var songs: [Song] {
            get {
                playlistItems
                    .sorted { $0.order < $1.order }
                    .compactMap { $0.song }
            }
            set {
                var newPlaylistItems = [PlaylistItem]()
                for song in newValue {
                    if let existingItem = playlistItems.first(where: { $0.song?.id == song.id }) {
                        existingItem.order = newPlaylistItems.count
                        newPlaylistItems.append(existingItem)
                    } else {
                        newPlaylistItems.append(PlaylistItem(playlist: self,
                                                             song: song,
                                                             order: newPlaylistItems.count))
                    }
                }
                playlistItems = newPlaylistItems
            }
        }
        
        var sortedSongs: [Song] {
            songs // Already in user-defined order
        }
    }
    
    @Model final class PlaylistItem {
        init(playlist: Playlist,
             song: Song,
             order: Int) {
            self.playlist = playlist
            self.song = song
            self.order = order
        }
        
        @Relationship(inverse: \Playlist.playlistItems) var playlist: Playlist?
        @Relationship(inverse: \Song.playlistItems) var song: Song?
        var order: Int
    }
}
