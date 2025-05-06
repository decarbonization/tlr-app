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

struct SongBrowser: View {
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
        customizations[visibility: "rating"] = .hidden
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
    @AppStorage("RatingStyle") private var ratingStyle = RatingStyle.default
    @Environment(Player.self) private var player
    @Environment(\.modelContext) private var modelContext
    
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
        ScrollViewReader { scrollView in
            QueryView(fetchDescriptor: $fetchDescriptor) { songs in
                Table(selection: $selection, sortOrder: $fetchDescriptor.sortBy, columnCustomization: $columnCustomization) {
                    Group {
                        TableColumn("Title", sortUsing: SortDescriptor(\Song.title)) { song in
                            HStack(alignment: .firstTextBaseline, spacing: 4.0) {
                                let isPlayingItem = song.extensionID == player.playingItem?.id
                                Image(systemName: "speaker.wave.2")
                                    .opacity(isPlayingItem ? 1 : 0)
                                    .accessibilityLabel(Text(isPlayingItem ? "Now Playing" : ""))
                                Text(verbatim: song.title ?? "")
                            }
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
                    
                    Group {
                        TableColumn("Rating", sortUsing: SortDescriptor(\Song.lastPlayed)) { song in
                            switch ratingStyle {
                            case .binary:
                                if song.rating != nil && song.rating != 1 {
                                    Label("Like", systemImage: "hand.thumbsup")
                                        .labelStyle(.iconOnly)
                                } else if song.rating == 1 {
                                    Label("Dislike", systemImage: "hand.thumbsdown")
                                        .labelStyle(.iconOnly)
                                }
                            case .stars:
                                if let rating = song.rating {
                                    Text(String(repeating: "􀋃", count: Int(rating)) + String(repeating: "􀋂", count: 5 - Int(rating)))
                                        .accessibilityLabel("\(rating) Stars")
                                }
                            }
                        }
                        .customizationID("rating")
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
                    ItemContextMenuContent(selection: selection)
                } primaryAction: { selection in
                    guard let songID = selection.first else {
                        return
                    }
                    Task {
                        do {
                            player.queue.replace(withContentsOf: songs.lazy.map { $0.id }, pinning: songID)
                            try await player.playItem(withID: songID)
                        } catch {
                            TaskErrors.all.present(error)
                        }
                    }
                }
                .revealInLibrary { itemIDs in
                    let newSelection = Set(
                        itemIDs
                            .lazy
                            .filter { $0.entityName == Schema.entityName(for: Song.self) }
                    )
                    selection = newSelection
                    if let firstItemID = newSelection.first {
                        scrollView.scrollTo(firstItemID)
                    }
                }
                .onDropOfImportableItems()
            }
        }
    }
}
