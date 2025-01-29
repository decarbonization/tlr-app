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

import SwiftData
import SwiftUI

struct SongList: View {
    init(filter: Predicate<Song>? = nil) {
        _songs = .init(filter: filter)
    }
    
    @Query private var songs: [Song]
    @Environment(\.modelContext) private var modelContext
    @Environment(PlayQueue.self) private var playQueue
    @State private var selection = Set<PersistentIdentifier>()
    @State private var sortOrder = [KeyPathComparator(\Song.title)]
    
    var body: some View {
        Table(songs, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Title", sortUsing: KeyPathComparator(\Song.title)) { song in
                Text(verbatim: song.title ?? "")
            }
            TableColumn("Album", sortUsing: KeyPathComparator(\Song.album?.title)) { song in
                Text(verbatim: song.album?.title ?? "")
            }
            TableColumn("Artist", sortUsing: KeyPathComparator(\Song.artist?.name)) { song in
                Text(verbatim: song.artist?.name ?? "")
            }
        }
        .contextMenu(forSelectionType: PersistentIdentifier.self) { selection in
            Button("Remove") {
                
            }
        } primaryAction: { selection in
            guard let songID = selection.first,
                  let songPosition = songs.firstIndex(where: { $0.id == songID }) else {
                return
            }
            try! playQueue.play(songs, startingAt: songPosition)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { itemProviders in
            let library = Library(modelContainer: modelContext.container)
            Task {
                try await importItems(itemProviders, into: library)
            }
            return true
        }
    }
}
