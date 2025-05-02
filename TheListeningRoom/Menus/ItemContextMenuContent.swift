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

struct ItemContextMenuContent: View {
    init(selection: Set<PersistentIdentifier>) {
        self.selection = selection
    }
    
    private let selection: Set<PersistentIdentifier>
    @Environment(\.modelContext) private var modelContext
    @Environment(Player.self) private var player
    @Environment(\.revealInLibrary) private var revealInLibrary
    
    var body: some View {
        Group {
            ItemAddToPlaylistMenu(selection: selection)
            Divider()
            Button("Play Next") {
                guard let playingIndex = player.playingIndex else {
                    return
                }
                insertInQueue(at: playingIndex)
            }
            .disabled(player.playingIndex == nil)
            Button("Play Last") {
                insertInQueue(at: 0)
            }
            Divider()
            ItemRatingMenu(selection: selection)
            Divider()
            Button("Show in Finder") {
                revealSelectionInFinder()
            }
            Button("Reveal in Library") {
                revealSelectionInLibrary()
            }
            Divider()
            Button("Remove from Library") {
                deleteSelection()
            }
        }
        .disabled(selection.isEmpty)
    }
    
    private func insertInQueue(at offset: Int) {
        guard !selection.isEmpty else {
            return
        }
        let toAdd = selection.lazy
            .compactMap { modelContext.model(for: $0) as? SongCollection }
            .flatMap { $0.sortedSongs }
            .map { $0.id }
        player.queue.append(contentsOf: toAdd)
    }
    
    private func revealSelectionInFinder() {
        guard !selection.isEmpty else {
            return
        }
        let toReveal = [URL](
            selection.lazy
                .compactMap { modelContext.model(for: $0) as? SongCollection }
                .flatMap { $0.sortedSongs }
                .map { $0.url }
        )
        NSWorkspace.shared.activateFileViewerSelecting(toReveal)
    }
    
    private func revealSelectionInLibrary() {
        guard !selection.isEmpty else {
            return
        }
        revealInLibrary(selection)
    }
    
    private func deleteSelection() {
        guard !selection.isEmpty else {
            return
        }
        let toDelete = Set<PersistentIdentifier>(
            selection.lazy
                .compactMap { modelContext.model(for: $0) as? SongCollection }
                .flatMap { $0.sortedSongs }
                .map { $0.id }
        )
        Library.performChanges(inContainerOf: modelContext) { library in
            try await library.deleteSongs(withIDs: toDelete)
        } catching: { error in
            TaskErrors.all.present(error)
        }
    }
}
