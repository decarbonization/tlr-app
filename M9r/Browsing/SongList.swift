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
    private static var defaultColumnCustomizations: TableColumnCustomization<Song> {
        var customizations = TableColumnCustomization<Song>()
        customizations[visibility: "albumArtist"] = .hidden
        customizations[visibility: "composer"] = .hidden
        customizations[visibility: "genre"] = .hidden
        customizations[visibility: "grouping"] = .hidden
        customizations[visibility: "releaseDate"] = .hidden
        customizations[visibility: "trackNumber"] = .hidden
        customizations[visibility: "discNumber"] = .hidden
        customizations[visibility: "bpm"] = .hidden
        customizations[visibility: "creationDate"] = .hidden
        customizations[visibility: "lastModified"] = .hidden
        customizations[visibility: "lastPlayed"] = .hidden
        return customizations
    }
    
    init(filter: Predicate<Song>? = nil,
         selection: Set<PersistentIdentifier> = [],
         sortOrder: [SortDescriptor<Song>] = [SortDescriptor(\Song.title)]) {
        _fetchDescriptor = .init(wrappedValue: FetchDescriptor(predicate: filter, sortBy: sortOrder))
        _selection = .init(wrappedValue: selection)
    }
    
    @State private var fetchDescriptor: FetchDescriptor<Song>
    @State private var selection: Set<PersistentIdentifier>
    @SceneStorage("SongTableConfig") private var columnCustomization: TableColumnCustomization<Song> = Self.defaultColumnCustomizations
    @SceneStorage("SongShuffleEnabled") private var isShuffleEnabled: Bool = false
    @Environment(PlayQueue.self) private var playQueue
    @Environment(\.modelContext) private var modelContext
    
    private func addToQueue(_ selection: Set<PersistentIdentifier>) {
        guard !selection.isEmpty else {
            return
        }
        let toAdd = selection.compactMap { modelContext.model(for: $0) as? Song }
        playQueue.withItems { items in
            items.append(contentsOf: toAdd)
        }
    }
    
    private func revealSelectionInFinder(_ selection: Set<PersistentIdentifier>) {
        guard !selection.isEmpty else {
            return
        }
        let toReveal = selection.compactMap { modelContext.model(for: $0) as? Song }.map{ $0.url }
        NSWorkspace.shared.activateFileViewerSelecting(toReveal)
    }
    
    private func deleteSelection(_ selection: Set<PersistentIdentifier>) {
        guard !selection.isEmpty else {
            return
        }
        Library.performChanges(inContainerOf: modelContext) { library in
            try await library.deleteSongs(withIDs: selection)
        } catching: { error in
            TaskErrors.all.present(error)
        }
    }
    
    var body: some View {
        QueryView(fetchDescriptor: $fetchDescriptor) { songs in
            Table(selection: $selection, sortOrder: $fetchDescriptor.sortBy, columnCustomization: $columnCustomization) {
                Group {
                    TableColumn("Title", sortUsing: SortDescriptor(\Song.title)) { song in
                        Text(verbatim: song.title ?? "")
                    }
                    .customizationID("title")
                    
                    TableColumn("Album", sortUsing: SortDescriptor(\Song.album?.title)) { song in
                        Text(verbatim: song.album?.title ?? "")
                    }
                    .customizationID("album")
                    
                    TableColumn("Artist", sortUsing: SortDescriptor(\Song.album?.artist?.name)) { song in
                        Text(verbatim: song.artist?.name ?? "")
                    }
                    .customizationID("artist")
                    
                    TableColumn("Time") { song in
                        Text(song.duration, format: Duration.TimeFormatStyle(pattern: .minuteSecond))
                    }
                    .customizationID("duration")
                }
                
                Group {
                    TableColumn("Album Artist", sortUsing: SortDescriptor(\Song.albumArtist)) { song in
                        Text(verbatim: song.albumArtist ?? "")
                    }
                    .customizationID("albumArtist")
                    
                    TableColumn("Composer", sortUsing: SortDescriptor(\Song.composer)) { song in
                        Text(verbatim: song.composer ?? "")
                    }
                    .customizationID("composer")
                    
                    TableColumn("Genre", sortUsing: SortDescriptor(\Song.genre)) { song in
                        Text(verbatim: song.genre ?? "")
                    }
                    .customizationID("genre")
                    
                    TableColumn("Grouping", sortUsing: SortDescriptor(\Song.grouping)) { song in
                        Text(verbatim: song.grouping ?? "")
                    }
                    .customizationID("grouping")
                }
                
                Group {
                    TableColumn("Release Date", sortUsing: SortDescriptor(\Song.releaseDate)) { song in
                        Text(verbatim: song.releaseDate ?? "")
                    }
                    .customizationID("releaseDate")
                    
                    TableColumn("Track#", sortUsing: SortDescriptor(\Song.trackNumber)) { song in
                        Text(song.trackNumber ?? 0, format: .number)
                    }
                    .customizationID("trackNumber")
                    
                    TableColumn("Disc#", sortUsing: SortDescriptor(\Song.discNumber)) { song in
                        Text(song.discNumber ?? 0, format: .number)
                    }
                    .customizationID("discNumber")
                    
                    TableColumn("BPM", sortUsing: SortDescriptor(\Song.bpm)) { song in
                        Text(song.bpm ?? 0, format: .number)
                    }
                    .customizationID("bpm")
                }
                
                Group {
                    TableColumn("Date Added", sortUsing: SortDescriptor(\Song.creationDate)) { song in
                        Text(song.creationDate, format: .dateTime)
                    }
                    .customizationID("creationDate")
                    
                    TableColumn("Date Modified", sortUsing: SortDescriptor(\Song.lastModified)) { song in
                        Text(song.lastModified, format: .dateTime)
                    }
                    .customizationID("lastModified")
                    
                    TableColumn("Last Played", sortUsing: SortDescriptor(\Song.lastPlayed)) { song in
                        if let lastPlayed = song.lastPlayed {
                            Text(lastPlayed, format: .dateTime)
                        }
                    }
                    .customizationID("lastPlayed")
                    
                }
            } rows: {
                ForEach(songs) { song in
                    TableRow(song)
                        .draggable(LibraryItem(from: song))
                }
            }
            .onDeleteCommand {
                deleteSelection(selection)
            }
            .contextMenu(forSelectionType: PersistentIdentifier.self) { selection in
                Button("Add to Queue") {
                    addToQueue(selection)
                }
                Button("Show in Finder") {
                    revealSelectionInFinder(selection)
                }
                Button("Remove from Library") {
                    deleteSelection(selection)
                }
            } primaryAction: { selection in
                guard let songID = selection.first,
                      let songPosition = songs.firstIndex(where: { $0.id == songID }) else {
                    return
                }
                do {
                    if isShuffleEnabled {
                        var shuffledSongs = songs.shuffled()
                        if let toMove = shuffledSongs.firstIndex(where: { $0.id == songID }) {
                            shuffledSongs.move(fromOffsets: [toMove], toOffset: 0)
                        }
                        try playQueue.play(shuffledSongs)
                    } else {
                        try playQueue.play(songs, startingAt: songPosition)
                    }
                } catch {
                    TaskErrors.all.present(error)
                }
            }
            .onDropOfImportableItems()
            .toolbar {
                ShuffleModeControl(isEnabled: $isShuffleEnabled)
            }
        }
    }
}
