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

import SwiftUI

struct PlaybackTabView: View {
    private struct TabID: RawRepresentable, Hashable, Codable {
        var rawValue: String
        
        static let nowPlaying = Self(rawValue: "nowPlaying")
        static let upNext = Self(rawValue: "upNext")
        static let search = Self(rawValue: "search")
        static var allBuiltIn: [Self] {
            [
                .nowPlaying,
                .upNext,
                .search,
            ]
        }
    }
    
    @AppStorage("SelectedPlaybackTab") private var selection = TabID.nowPlaying
    @Environment(Player.self) private var player
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 0) {
            TablessView(TabID.allBuiltIn,
                        selection: $selection) { tabID in
                switch tabID {
                case .nowPlaying:
                    NowPlaying()
                case .upNext:
                    UpNextList()
                case .search:
                    SearchView()
                        .searchSource(ArtistSearchSource(modelContainer: modelContext.container))
                        .searchSource(AlbumSearchSource(modelContainer: modelContext.container))
                        .searchSource(SongSearchSource(modelContainer: modelContext.container))
                default:
                    EmptyView()
                }
            }
            Divider()
            HStack(alignment: .center) {
                ForEach(TabID.allBuiltIn, id: \.rawValue) { tabID in
                    Button {
                        selection = tabID
                    } label: {
                        switch tabID {
                        case .nowPlaying:
                            Label("Now Playing", systemImage: "play.circle.fill")
                        case .upNext:
                            Label("Up Next", systemImage: "music.note.list")
                        case .search:
                            Label("Search", systemImage: "magnifyingglass")
                        default:
                            EmptyView()
                        }
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderless)
                    .foregroundStyle(tabID == selection ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                }
            }
            .padding()
        }
        .toolbar {
            Volume()
            Spacer()
            RepeatModeControl(repeatMode: Binding(get: { player.queue.repeatMode },
                                                  set: { player.queue.repeatMode = $0 }))
            ShuffleModeControl(isEnabled: Binding(get: { player.queue.isShuffleEnabled },
                                                  set: { player.queue.isShuffleEnabled = $0 }))
        }
    }
}
