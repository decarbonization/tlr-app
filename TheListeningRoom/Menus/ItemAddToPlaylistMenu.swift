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

struct ItemAddToPlaylistMenu: View {
    init(selection: Set<PersistentIdentifier>) {
        self.selection = selection
    }
    
    private let selection: Set<PersistentIdentifier>
    @Query(sort: \Playlist.name) private var playlists: [Playlist]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Menu("Add to Playlist") {
            ForEach(playlists) { playlist in
                Button {
                    add(to: playlist)
                } label: {
                    Label(playlist.name, systemImage: "music.note.list")
                }
            }
        }
        .disabled(playlists.isEmpty)
    }
    
    private func add(to playlist: Playlist) {
        let toAdd = selection.lazy
            .compactMap { modelContext.model(for: $0) as? any SongCollection }
            .flatMap { $0.sortedSongs }
        playlist.songs.append(contentsOf: toAdd)
    }
}
