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
    @State private var selection = Set<[PersistentIdentifier]>()
    @Environment(\.searchSources) private var searchSources
    @Environment(Player.self) private var player
    
    var body: some View {
        VStack(spacing: 0) {
            TextField(text: $query) {
                Text("Search")
            }
            .textFieldStyle(.roundedBorder)
            .padding(2)
            Divider()
            List(selection: $selection) {
                ForEach(resultGroups) { resultGroup in
                    Section {
                        ForEach(resultGroup.results) { result in
                            SearchResultItem(result: result)
                        }
                    } header: {
                        if let title = resultGroup.title {
                            Text(verbatim: title)
                        }
                    }
                }
            }
            .contextMenu(forSelectionType: [PersistentIdentifier].self) { selection in
                ItemContextMenuContent(selection: Set(selection.lazy.flatMap { $0 }))
            } primaryAction: { selection in
                guard let songID = selection.first?.first else {
                    return
                }
                Task {
                    do {
                        player.queue.replace(withContentsOf: resultGroups.lazy.flatMap { $0.results.lazy.flatMap { $0.items } }, pinning: songID)
                        try await player.playItem(withID: songID)
                    } catch {
                        TaskErrors.all.present(error)
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
                try await Task.sleep(for: .milliseconds(64))
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
