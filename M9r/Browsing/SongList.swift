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

import SwiftUI

struct SongList: View {
    @Environment(PlayQueue.self) var playQueue
    @Environment(\.library) var library
    @State private var selectedSongs = Set<LibraryID>()
    
    var body: some View {
        Table(library.allSongs, selection: $selectedSongs) {
            TableColumn("Title") { song in
                Text(verbatim: song.title ?? "")
            }
            TableColumn("Album") { song in
                Text(verbatim: song.album ?? "")
            }
            TableColumn("Artist") { song in
                Text(verbatim: song.artist ?? "")
            }
        }
        .contextMenu(forSelectionType: LibraryID.self) { selection in
            Button("Remove") {
                Task {
                    try await library.deleteSongs(selection)
                }
            }
        } primaryAction: { selection in
            guard let songID = selection.first,
                  let toPlay = library.allSongs.firstIndex(where: { $0.id == songID }) else {
                return
            }
            try! playQueue.play(library.allSongs, startingAt: toPlay)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                let progress = provider.loadTransferable(type: URL.self) { result in
                    let url = try! result.get()
                    Task {
                        let toAdd = try collectSongFiles(at: url)
                        try await library.importSongs(toAdd)
                    }
                }
                if progress.isCancelled {
                    return false
                }
            }
            return true
        }
    }
}
