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
    @Environment(Tasks.self) private var tasks
    @Environment(\.presentErrors) private var presentErrors
    @Environment(\.modelContext) private var modelContext
    @State private var selectedItems = Set<PersistentIdentifier>()
    
    var body: some View {
        @Bindable var playQueue = playQueue
        
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                List(selection: $selectedItems) {
                    ForEach(playQueue.items) { item in
                        let position = playQueue.relativeItemPosition(item)
                        Text(verbatim: item.title ?? "")
                            .foregroundStyle(
                                position == .orderedDescending ? .secondary :
                                    position == .orderedAscending ? .tertiary
                                : .primary
                            )
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
                        let loadProgress = loadAll(LibraryItem.self, from: providers) { results, loadProgress in
                            tasks.remove(loadProgress)
                            var songs = [Song]()
                            var errors = [any Error]()
                            for result in results {
                                switch result {
                                case .success(let libraryItem):
                                    if let song = libraryItem.model(from: modelContext, as: Song.self) {
                                        songs.append(song)
                                    } else {
                                        errors.append(CocoaError(.persistentStoreUnsupportedRequestType, userInfo: [
                                            NSLocalizedDescriptionKey: "Could not load song for \(libraryItem)",
                                        ]))
                                    }
                                case .failure(let error):
                                    errors.append(error)
                                }
                            }
                            playQueue.withItems { items in
                                items.insert(contentsOf: songs, at: offset)
                            }
                            presentErrors(errors)
                        }
                        tasks.add(loadProgress)
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
                        presentErrors(error)
                    }
                }
                .onChange(of: playQueue.playingItem) {
                    guard let playingItem = playQueue.playingItem else {
                        return
                    }
                    proxy.scrollTo(playingItem.persistentModelID, anchor: .center)
                }
            }
            NowPlaying()
        }
    }
}
