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

import CoreTransferable
import Foundation
import SwiftData
import UniformTypeIdentifiers

extension UTType {
    static let musicLibrary = UTType(exportedAs: "io.github.decarbonization.M9r.musicLibrary",
                                     conformingTo: .database)
    
    static let libraryItem = UTType(exportedAs: "io.github.decarbonization.M9r.item",
                                    conformingTo: .content)
}

struct LibraryItem: Identifiable, Equatable, Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .libraryItem) { libraryItem in
            return try JSONEncoder().encode(libraryItem.id)
        } importing: { libraryItemData in
            let id = try JSONDecoder().decode(PersistentIdentifier.self, from: libraryItemData)
            return LibraryItem(id: id)
        }

    }
    
    init(from model: some PersistentModel) {
        self.id = model.persistentModelID
    }
    
    init(id: PersistentIdentifier) {
        self.id = id
    }
    
    let id: PersistentIdentifier
    
    func model<Model>(from modelContext: ModelContext,
                      as modelType: Model.Type = Model.self) -> Model? {
        modelContext.model(for: id) as? Model
    }
}

func makeAppModelConatiner() -> ModelContainer {
    let appSchema = Schema(versionedSchema: LatestAppSchema.self)
    let appLibraryURL = UserDefaults.standard.url(forKey: "M9r_libraryURL")
        ?? URL.musicDirectory.appending(path: "Music Library.m9rl", directoryHint: .notDirectory)
    let appModelConfiguration = ModelConfiguration("M9r Music Library",
                                                   schema: appSchema,
                                                   url: appLibraryURL,
                                                   allowsSave: true,
                                                   cloudKitDatabase: .none)
    do {
        let appModelContainer = try ModelContainer(for: appSchema,
                                                   migrationPlan: AppSchemaMigrationPlan.self,
                                                   configurations: appModelConfiguration)
        Library.log.debug("Opened app library at <\(appLibraryURL)>")
        return appModelContainer
    } catch {
        Library.log.error("*** Could not open app library at <\(error)>, reason: \(error)")
        CFUserNotificationDisplayAlert(0,
                                       0,
                                       nil,
                                       nil,
                                       nil,
                                       "Could not open music library" as CFString,
                                       error.localizedDescription as CFString,
                                       "OK" as CFString,
                                       nil,
                                       nil,
                                       nil)
        exit(1)
    }
}
