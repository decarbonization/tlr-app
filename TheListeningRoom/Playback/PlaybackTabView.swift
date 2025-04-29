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
    
    private final class SelectingDropDelegate: DropDelegate {
        init(tabID: TabID,
             selection: Binding<TabID>) {
            self.tabID = tabID
            self._selection = selection
        }
        
        private let tabID: TabID
        @Binding private var selection: TabID
        private var changeSelection: Task<Void, any Error>?
        
        func dropEntered(info: DropInfo) {
            changeSelection = Task {
                // Add a small amount of hysteresis so the UI doesn't feel
                // like it's flapping in the wind as you drag something over it.
                try await Task.sleep(for: .milliseconds(200))
                if selection != tabID {
                    selection = tabID
                }
            }
        }
        
        func dropExited(info: DropInfo) {
            changeSelection?.cancel()
        }
        
        func performDrop(info: DropInfo) -> Bool {
            false
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
            HStack(alignment: .center, spacing: 8) {
                ForEach(TabID.allBuiltIn, id: \.rawValue) { tabID in
                    Button {
                        selection = tabID
                    } label: {
                        switch tabID {
                        case .nowPlaying:
                            Label("Now Playing", systemImage: "play.circle.fill")
                                .labelStyle(.playbackTabLabel(isHighlighted: tabID == selection))
                        case .upNext:
                            Label("Up Next", systemImage: "music.note.list")
                                .labelStyle(.playbackTabLabel(isHighlighted: tabID == selection))
                        case .search:
                            Label("Search", systemImage: "magnifyingglass")
                                .labelStyle(.playbackTabLabel(isHighlighted: tabID == selection))
                        default:
                            EmptyView()
                        }
                    }
                    .buttonStyle(.borderless)
                    .onDrop(of: [.fileURL, .libraryItem], delegate: SelectingDropDelegate(tabID: tabID, selection: $selection))
                }
            }
            .padding(8)
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
