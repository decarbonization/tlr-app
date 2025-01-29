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
    @Observable final class Tasks: Sendable {
        init() {
            _inProgress = .init(initialState: [])
        }
        
        private let _inProgress: OSAllocatedUnfairLock<[Progress]>
        
        var inProgress: [Progress] {
            access(keyPath: \.inProgress)
            return _inProgress.withLock { $0 }
        }
        
        func add(_ newProgress: Progress) {
            withMutation(keyPath: \.inProgress) {
                _inProgress.withLock { active in
                    active.append(newProgress)
                }
            }
        }
        
        func remove(_ oldProgress: Progress) {
            withMutation(keyPath: \.inProgress) {
                _inProgress.withLock { active in
                    guard let toRemove = active.firstIndex(of: oldProgress) else {
                        return
                    }
                    active.remove(at: toRemove)
                }
            }
        }
    }
    
    static let log = Logger(subsystem: "io.github.decarbonization.M9r", category: "Library")
    
    nonisolated let tasks = Tasks()
    
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
    
    func garbageCollect() throws {
        try modelContext.delete(model: Album.self, where: #Predicate { $0.songs.isEmpty })
        try modelContext.delete(model: Artist.self, where: #Predicate { $0.songs.isEmpty })
    }
    
    func save() throws {
        try modelContext.save()
    }
}
