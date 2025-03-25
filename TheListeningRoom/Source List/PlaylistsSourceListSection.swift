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

struct PlaylistsSourceListSection: View {
    @Query(sort: \Playlist.name) private var playlists: [Playlist]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Section("Playlists") {
            ForEach(playlists) { playlist in
                NavigationLink {
                    PlaylistList(playlist: playlist)
                } label: {
                    Label {
                        @Bindable var playlist = playlist
                        TextField("Playlist Name", text: $playlist.name)
                    } icon: {
                        Image(systemName: "music.note.list")
                    }
                }
                .onDrag {
                    let itemProvider = NSItemProvider()
                    itemProvider.register(LibraryItem(from: playlist))
                    return itemProvider
                }
                .onDrop(of: [.libraryItem], isTargeted: nil) { providers in
                    Task(priority: .userInitiated) {
                        let itemResults = await loadAll(LibraryItem.self, from: providers)
                        let collectionsResults = mapResults(itemResults) { libraryItem in
                            guard let song = libraryItem.model(from: modelContext, as: SongCollection.self) else {
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
    }
}
