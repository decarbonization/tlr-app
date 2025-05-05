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

import Foundation
import SwiftData

protocol ExternallyIdentifiable {
    var externalID: String { get }
}

extension ExternallyIdentifiable where Self: PersistentModel {
    static func model(for externalID: String, in modelContext: ModelContext) -> Self? {
        var whatModel = FetchDescriptor<Self>(predicate: #Predicate { $0.externalID == externalID })
        whatModel.fetchLimit = 1
        whatModel.includePendingChanges = true
        guard let results = try? modelContext.fetch(whatModel),
              results.count == 1 else {
            return nil
        }
        return results[0]
    }
    
    static func persistentModelID(for externalID: String, in modelContext: ModelContext) -> PersistentIdentifier? {
        var whatModel = FetchDescriptor<Self>(predicate: #Predicate { $0.externalID == externalID })
        whatModel.fetchLimit = 1
        whatModel.includePendingChanges = true
        guard let results = try? modelContext.fetchIdentifiers(whatModel),
              results.count == 1 else {
            return nil
        }
        return results[0]
    }
}
