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
import UniformTypeIdentifiers

struct PlaylistBrowser: View {
    @State private var selection: Playlist?
    @Query(sort: \Playlist.name) private var playlists: [Playlist]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HSplitView {
            VStack(alignment: .leading) {
                List(selection: $selection) {
                    ForEach(playlists) { playlist in
                        Label {
                            @Bindable var playlist = playlist
                            TextField("Playlist Name", text: $playlist.name)
                        } icon: {
                            Image(systemName: "music.note.list")
                                .allowsHitTesting(false)
                        }
                        .tag(playlist)
                        .onDrag {
                            let itemProvider = NSItemProvider()
                            let libraryItem = LibraryItem(from: playlist)
                            itemProvider.register(libraryItem)
                            return itemProvider
                        }
                        .onDrop(of: [.libraryItem], isTargeted: nil) { providers in
                            Task(priority: .userInitiated) {
                                let itemResults = await loadAll(LibraryItem.self, from: providers)
                                let collectionsResults = mapResults(itemResults) { libraryItem in
                                    guard let song = libraryItem.model(from: modelContext, as: (any SongCollection).self) else {
                                        throw CocoaError(.persistentStoreUnsupportedRequestType, userInfo: [
                                            NSLocalizedDescriptionKey: "Could not load songs from \(libraryItem)",
                                        ])
                                    }
                                    return song
                                }
                                let (collections, errors) = extractResults(collectionsResults)
                                let allSongs = collections.flatMap { $0.sortedSongs }
                                playlist.songs.append(contentsOf: allSongs)
                                TaskErrors.all.present(errors)
                            }
                            return providers.contains(where: { $0.hasItemConformingToTypeIdentifier(UTType.libraryItem.identifier) })
                        }
                        .contextMenu {
                            Button("Delete from Library") {
                                modelContext.delete(playlist)
                            }
                        }
                    }
                }
                HStack {
                    Button {
                        modelContext.insert(Playlist(name: "Untitled Playlist"))
                    } label: {
                        Label("New Playlist", systemImage: "plus")
                    }
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .padding()
            }
            .frame(minWidth: 100, idealWidth: 150, maxWidth: 250)
            
            VStack(alignment: .leading, spacing: 0.0) {
                if let selection {
                    PlaylistList(playlist: selection)
                } else {
                    NoContentView("No Selection")
                }
            }
        }
        .onDropOfImportableItems()
    }
}
