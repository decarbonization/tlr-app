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
    init(filter: Predicate<Song>? = nil,
         selection: Set<PersistentIdentifier> = [],
         sortOrder: [SortDescriptor<Song>] = [SortDescriptor(\Song.title)]) {
        _filter = .init(wrappedValue: filter)
        _selection = .init(wrappedValue: selection)
        _sortOrder = .init(wrappedValue: sortOrder)
    }
    
    @State private var filter: Predicate<Song>?
    @State private var selection: Set<PersistentIdentifier>
    @State private var sortOrder: [SortDescriptor<Song>]
    
    var body: some View {
        _SongListBody(filter: $filter,
                      selection: $selection,
                      sortOrder: $sortOrder)
    }
}

private struct _SongListBody: View {
    init(filter: Binding<Predicate<Song>?>,
         selection: Binding<Set<PersistentIdentifier>>,
         sortOrder: Binding<[SortDescriptor<Song>]>) {
        _songs = .init(filter: filter.wrappedValue, sort: sortOrder.wrappedValue)
        _selection = selection
        _sortOrder = sortOrder
    }
    
    @Query private var songs: [Song]
    @Environment(PlayQueue.self) private var playQueue
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentErrors) private var presentErrors
    @Binding private var selection: Set<PersistentIdentifier>
    @Binding private var sortOrder: [SortDescriptor<Song>]
    
    private func deleteSelection() {
        guard !selection.isEmpty else {
            return
        }
        Library.performChanges(inContainerOf: modelContext) { library in
            try await library.deleteSongs(withIDs: selection)
        } catching: { error in
            await presentErrors(error)
        }
    }
    
    var body: some View {
        Table(selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Title", sortUsing: SortDescriptor(\Song.title)) { song in
                Text(verbatim: song.title ?? "")
            }
            TableColumn("Album", sortUsing: SortDescriptor(\Song.album?.title)) { song in
                Text(verbatim: song.album?.title ?? "")
            }
            TableColumn("Artist", sortUsing: SortDescriptor(\Song.album?.artist?.name)) { song in
                Text(verbatim: song.artist?.name ?? "")
            }
        } rows: {
            ForEach(songs) { song in
                TableRow(song)
                    .draggable(LibraryItem(from: song))
            }
        }
        .onDeleteCommand {
            deleteSelection()
        }
        .contextMenu(forSelectionType: PersistentIdentifier.self) { selection in
            Button("Add to Queue") {
                let toAdd = songs.filter { selection.contains($0.persistentModelID) }
                playQueue.withItems { items in
                    items.append(contentsOf: toAdd)
                }
            }
            Button("Remove from Library") {
                deleteSelection()
            }
        } primaryAction: { selection in
            guard let songID = selection.first,
                  let songPosition = songs.firstIndex(where: { $0.id == songID }) else {
                return
            }
            do {
                try playQueue.play(songs, startingAt: songPosition)
            } catch {
                presentErrors(error)
            }
        }
        .onDropOfImportableItems()
    }
}
