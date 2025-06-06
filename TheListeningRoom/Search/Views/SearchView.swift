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

import TheListeningRoomExtensionSDK
import SwiftData
import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var resultGroups = [ListeningRoomSearchResultGroup]()
    @State private var selection = Set<ListeningRoomID>()
    @Environment(\.searchSources) private var searchSources
    @Environment(\.modelContext) private var modelContext
    @Environment(Player.self) private var player
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(text: $query) {
                    Text("Search")
                }
                .textFieldStyle(.plain)
            }
            .padding(8)
            Divider()
            List(selection: $selection) {
                ForEach(resultGroups) { resultGroup in
                    Section {
                        ForEach(resultGroup.results) { result in
                            SearchResultItem(result: result)
                                .onDrag {
                                    let itemProvider = NSItemProvider()
                                    let libraryIDs = persistentModelIDs(for: result.itemIDs, in: modelContext)
                                    for libraryID in libraryIDs {
                                        itemProvider.register(LibraryItem(id: libraryID))
                                    }
                                    return itemProvider
                                }
                        }
                    } header: {
                        if let title = resultGroup.title {
                            Text(verbatim: title)
                        }
                    }
                }
            }
            .contextMenu(forSelectionType: ListeningRoomID.self) { selection in
                ItemContextMenuContent(selection: Set(persistentModelIDs(for: selection, in: modelContext)))
            } primaryAction: { selection in
                guard let resultID = selection.first,
                      let result = resultGroups.lazy.compactMap({ $0.results.first(where: { $0.id == resultID }) }).first,
                      let resultID = result.itemIDs.first,
                      let songID = Song.persistentModelID(for: resultID, in: modelContext) else {
                    return
                }
                Task {
                    do {
                        player.queue.replace(withContentsOf: resultGroups.lazy.flatMap { $0.results.lazy.flatMap { persistentModelIDs(for: $0.itemIDs, in: modelContext) } }, pinning: songID)
                        try await player.playItem(withID: songID)
                    } catch {
                        AppNotificationCenter.global.present(ListeningRoomNotification(presenting: error))
                    }
                }
            }
        }
        .task(id: query) {
            resultGroups.removeAll()
            
            guard !query.isEmpty else {
                return
            }
            do {
                try await Task.sleep(for: .milliseconds(100))
            } catch {
                return
            }
            for searchSource in searchSources {
                do {
                    let searchResults = try await searchSource.search(for: query)
                    if !searchResults.isEmpty && !searchResults.allSatisfy({ $0.results.isEmpty }) {
                        guard !Task.isCancelled else {
                            break
                        }
                        resultGroups.append(contentsOf: searchResults)
                    }
                } catch {
                    
                }
            }
        }
    }
}
