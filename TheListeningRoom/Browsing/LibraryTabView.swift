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

import SwiftData
import SwiftUI

struct LibraryTabView: View {
    private struct TabID: RawRepresentable, Hashable, Codable {
        var rawValue: String
        
        static let artists = Self(rawValue: "artists")
        static let albums = Self(rawValue: "albums")
        static let songs = Self(rawValue: "songs")
        static let playlists = Self(rawValue: "playlists")
        static var allBuiltIn: [Self] {
            [
                .artists,
                .albums,
                .songs,
                .playlists,
            ]
        }
    }
    
    init() {
    }
    
    @AppStorage("SelectedLibraryTab") private var selection = TabID.songs
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        TablessView(TabID.allBuiltIn,
                    selection: $selection) { tabID in
            switch tabID {
            case .artists:
                ArtistBrowser()
            case .albums:
                AlbumBrowser()
            case .songs:
                SongBrowser()
            case .playlists:
                PlaylistBrowser()
            default:
                EmptyView()
            }
        }
        .toolbar {
            Spacer()
            Picker("Browse", selection: $selection) {
                ForEach(TabID.allBuiltIn, id: \.rawValue) { tabID in
                    Group {
                        switch tabID {
                        case .artists:
                            Label("Artists", systemImage: "music.microphone")
                        case .albums:
                            Label("Albums", systemImage: "square.stack")
                        case .songs:
                            Label("Songs", systemImage: "music.note")
                        case .playlists:
                            Label("Playlists", systemImage: "music.note.list")
                        default:
                            EmptyView()
                        }
                    }
                    .tag(tabID)
                }
            }
            .labelStyle(.titleAndIcon)
            .pickerStyle(.segmented)
            Spacer()
            NotificationsButton()
        }
    }
}
