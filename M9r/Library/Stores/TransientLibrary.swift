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

import Foundation

/// Q&D placeholder library implementation
@Observable final class TransientLibrary: Library {
    init() {
        allSongs = []
    }
    
    var allSongs: [LibrarySong]
    
    func importSongs(_ urls: some Sequence<URL>) async throws -> Set<LibraryID> {
        let newSongs = try await Task {
            try urls.map { try LibrarySong.importing(contentsOf: $0) }
        }.value
        allSongs.append(contentsOf: newSongs)
        return Set(allSongs.lazy.map { $0.id })
    }
    
    func updateSongs(_ songs: inout some MutableCollection<LibrarySong>,
                     writingToFiles updateFiles: Bool) async throws {
        let updates = try songs.map { song in
            guard let toUpdate = allSongs.firstIndex(where: { $0.id == song.id }) else {
                throw CocoaError(.fileNoSuchFile)
            }
            return (toUpdate, song)
        }
        for (index, newSong) in updates {
            allSongs[index] = newSong
        }
    }
    
    func deleteSongs(_ songIDs: some Sequence<LibraryID>) async throws -> Set<LibraryID> {
        let toRemove = try await Task {
            IndexSet(try songIDs.lazy.map { songID in
                guard let toRemove = allSongs.firstIndex(where: { $0.id == songID }) else {
                    throw CocoaError(.fileNoSuchFile)
                }
                return toRemove
            })
        }.value
        let removedIDs = Set(toRemove.lazy.map { self.allSongs[$0].id })
        allSongs.remove(atOffsets: toRemove)
        return removedIDs
    }
}
