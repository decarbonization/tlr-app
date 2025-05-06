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
import TheListeningRoomExtensionSDK

struct UpNextList: View {
    @Environment(Player.self) private var player
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItems = Set<ListeningRoomID>()
    
    private func insert(contentsOf providers: [NSItemProvider], at offset: Int) {
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
            player.queue.insert(contentsOf: allSongs.lazy.map { $0.id }, at: offset)
            TaskErrors.all.present(errors)
        }
    }
    
    var body: some View {
        if player.queue.itemIDs.isEmpty {
            NoContentView("No Songs")
                .onDrop(of: [.libraryItem], isTargeted: nil) { providers in
                    insert(contentsOf: providers, at: 0)
                    return providers.contains { $0.hasItemConformingToTypeIdentifier(UTType.libraryItem.identifier) }
                }
        } else {
            ScrollViewReader { proxy in
                List(selection: $selectedItems) {
                    ForEach(player.queue.items(of: Song.self).indexed, id: \.element.id) { (item, index) in
                        QueueItem(isPlaying: player.playingItem?.id == item.extensionID,
                                  isHistory: index < player.playingIndex ?? 0,
                                  item: item)
                    }
                    .onDelete { toRemove in
                        player.queue.remove(atOffsets: toRemove)
                    }
                    .onMove { source, destination in
                        player.queue.move(fromOffsets: source, toOffset: destination)
                    }
                    .onInsert(of: [.libraryItem]) { (offset: Int, providers: [NSItemProvider]) in
                        insert(contentsOf: providers, at: offset)
                    }
                }
                .contextMenu(forSelectionType: PersistentIdentifier.self) { selection in
                    Button("Remove from Queue") {
                        player.queue.remove(withIDs: selection)
                    }
                } primaryAction: { selection in
                    guard let songID = selection.first else {
                        return
                    }
                    Task {
                        do {
                            try await player.playItem(withID: songID)
                        } catch {
                            TaskErrors.all.present(error)
                        }
                    }
                }
            }
        }
    }
}
