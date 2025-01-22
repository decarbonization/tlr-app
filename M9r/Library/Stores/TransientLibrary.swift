//
//  TransientLibrary.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/22/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import Foundation

/// Q&D placeholder library implementation
@MainActor @Observable final class TransientLibrary: Library {
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
    
    func deleteSongs(_ songs: some Sequence<LibrarySong>) async throws -> Set<LibraryID> {
        let toRemove = try await Task {
            IndexSet(try songs.lazy.map { song in
                guard let toRemove = allSongs.firstIndex(where: { $0.id == song.id }) else {
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
