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
import os
import SwiftData

@ModelActor actor Library {
    static let log = Logger(subsystem: "io.github.decarbonization.M9r", category: "Library")
    
    func getOrInsert<Model: PersistentModel>(matching filter: Predicate<Model>,
                                             otherwise makeModel: () throws -> Model) throws -> Model {
        var what = FetchDescriptor<Model>(predicate: filter)
        what.fetchLimit = 1
        what.includePendingChanges = true
        let existingModel = try modelContext.fetch(what)
        if existingModel.count == 1 {
            return existingModel[0]
        } else {
            let newModel = try makeModel()
            modelContext.insert(newModel)
            return newModel
        }
    }
    
    static func performChanges(inContainerOf modelContext: ModelContext,
                               _ changes: @escaping @Sendable (Library) async throws -> Void,
                               catching onError: @escaping @Sendable (any Error) async -> Void) {
        let library = Library(modelContainer: modelContext.container)
        Task.detached(priority: .userInitiated) {
            do {
                try await changes(library)
                try await library.garbageCollect()
                try await library.save()
            } catch {
                await onError(error)
            }
        }
    }
    
    func garbageCollect() throws {
        var emptyAlbumsFetch = FetchDescriptor<Album>(predicate: #Predicate { $0.songs.isEmpty })
        emptyAlbumsFetch.includePendingChanges = true
        let emptyAlbums = try modelContext.fetch(emptyAlbumsFetch)
        for emptyAlbum in emptyAlbums {
            emptyAlbum.artist = nil
            modelContext.delete(emptyAlbum)
        }
        
        var emptyArtistFetch = FetchDescriptor<Artist>(predicate: #Predicate { $0.songs.isEmpty })
        emptyArtistFetch.includePendingChanges = true
        let emptyArtist = try modelContext.fetch(emptyArtistFetch)
        for emptyArtist in emptyArtist {
            emptyArtist.albums = []
            modelContext.delete(emptyArtist)
        }
    }
    
    func save() throws {
        try modelContext.save()
    }
}
