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
import UniformTypeIdentifiers

struct QueueList: View {
    @Environment(PlayQueue.self) private var playQueue
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItems = Set<PersistentIdentifier>()
    
    private func insert(contentsOf providers: [NSItemProvider], at offset: Int) {
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
            playQueue.withItems { items in
                items.insert(contentsOf: allSongs, at: offset)
            }
            TaskErrors.all.present(errors)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if playQueue.items.isEmpty {
                VStack(alignment: .center) {
                    Text("No Songs")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onDrop(of: [.libraryItem], isTargeted: nil) { providers in
                    insert(contentsOf: providers, at: 0)
                    return providers.contains { $0.hasItemConformingToTypeIdentifier(UTType.libraryItem.identifier) }
                }
            } else {
                ScrollViewReader { proxy in
                    List(selection: $selectedItems) {
                        ForEach(playQueue.items.indexed, id: \.element.id) { (item, index) in
                            QueueItem(isPlaying: playQueue.playingIndex == index,
                                      isHistory: index < playQueue.playingIndex ?? 0,
                                      item: item)
                        }
                        .onDelete { toRemove in
                            playQueue.withItems { items in
                                items.remove(atOffsets: toRemove)
                            }
                        }
                        .onMove { source, destination in
                            playQueue.withItems { items in
                                items.move(fromOffsets: source, toOffset: destination)
                            }
                        }
                        .onInsert(of: [.libraryItem]) { (offset: Int, providers: [NSItemProvider]) in
                            insert(contentsOf: providers, at: offset)
                        }
                    }
                    .contextMenu(forSelectionType: PersistentIdentifier.self) { selection in
                        Button("Remove from Queue") {
                            playQueue.withItems { items in
                                items.removeAll { item in
                                    selection.contains(item.id)
                                }
                            }
                        }
                    } primaryAction: { selection in
                        guard let songID = selection.first,
                              let toPlay = playQueue.items.firstIndex(where: { $0.id == songID }) else {
                            return
                        }
                        do {
                            try playQueue.play(playQueue.items, startingAt: toPlay)
                        } catch {
                            TaskErrors.all.present(error)
                        }
                    }
                    .onChange(of: playQueue.playingItem) {
                        guard let playingItem = playQueue.playingItem else {
                            return
                        }
                        proxy.scrollTo(playingItem.persistentModelID, anchor: .center)
                    }
                }
            }
            NowPlaying()
        }
        .toolbar {
            RepeatModeControl()
            Spacer()
            Volume()
            PlaybackControls()
        }
    }
}
