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
import TheListeningRoomExtensionSDK

protocol ExternallyIdentifiable: PersistentModel {
    static func makeUniqueExternalID() -> String
    static var externalEntity: ListeningRoomID.Entity { get }
    var externalID: String { get }
}

extension ExternallyIdentifiable where Self: PersistentModel {
    static func makeUniqueExternalID() -> String {
        "TLR:\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
    }
    
    static func model(for id: ListeningRoomID, in modelContext: ModelContext) -> Self? {
        guard id.entity == Self.externalEntity else {
            return nil
        }
        let externalID = id.value
        var whatModel = FetchDescriptor<Self>(predicate: #Predicate { $0.externalID == externalID })
        whatModel.fetchLimit = 1
        whatModel.includePendingChanges = true
        guard let results = try? modelContext.fetch(whatModel),
              results.count == 1 else {
            return nil
        }
        return results[0]
    }
    
    static func models(for ids: some Sequence<ListeningRoomID>, in modelContext: ModelContext) -> [Self] {
        let validExternalIDs = Set(ids.lazy.filter { $0.entity == Self.externalEntity }.map { $0.value })
        var whatModels = FetchDescriptor<Self>(predicate: #Predicate { validExternalIDs.contains($0.externalID) })
        whatModels.includePendingChanges = true
        guard let results = try? modelContext.fetch(whatModels) else {
            return []
        }
        return results
    }
    
    static func persistentModelID(for id: ListeningRoomID, in modelContext: ModelContext) -> PersistentIdentifier? {
        guard id.entity == Self.externalEntity else {
            return nil
        }
        let externalID = id.value
        var whatModel = FetchDescriptor<Self>(predicate: #Predicate { $0.externalID == externalID })
        whatModel.fetchLimit = 1
        whatModel.includePendingChanges = true
        guard let results = try? modelContext.fetchIdentifiers(whatModel),
              results.count == 1 else {
            return nil
        }
        return results[0]
    }
    
    static func persistentModelIDs(for ids: some Sequence<ListeningRoomID>, in modelContext: ModelContext) -> [PersistentIdentifier] {
        let validExternalIDs = Set(ids.lazy.filter { $0.entity == Self.externalEntity }.map { $0.value })
        var whatModels = FetchDescriptor<Self>(predicate: #Predicate { validExternalIDs.contains($0.externalID) })
        whatModels.includePendingChanges = true
        guard let results = try? modelContext.fetchIdentifiers(whatModels) else {
            return []
        }
        return results
    }
    
    static func listeningRoomIDs(for ids: some Sequence<PersistentIdentifier>, in modelContext: ModelContext) -> [ListeningRoomID] {
        [ListeningRoomID](
            ids.lazy
            .compactMap { modelContext.model(for: $0) as? Self }
            .map { $0.listeningRoomID }
        )
    }
    
    var listeningRoomID: ListeningRoomID {
        ListeningRoomID(entity: Self.externalEntity, value: self.externalID)
    }
}

func persistentModelIDs(for ids: some Sequence<ListeningRoomID>, in modelContext: ModelContext) -> Set<PersistentIdentifier> {
    var idsByEntity = [ListeningRoomID.Entity: Set<ListeningRoomID>]()
    for id in ids {
        idsByEntity[id.entity, default: []].insert(id)
    }
    
    var persistentModelIDs = Set<PersistentIdentifier>()
    for (entity, ids) in idsByEntity {
        switch entity {
        case .song:
            persistentModelIDs.formUnion(Song.persistentModelIDs(for: ids, in: modelContext))
        case .album:
            persistentModelIDs.formUnion(Album.persistentModelIDs(for: ids, in: modelContext))
        case .artist:
            persistentModelIDs.formUnion(Artist.persistentModelIDs(for: ids, in: modelContext))
        case .artwork:
            persistentModelIDs.formUnion(Artwork.persistentModelIDs(for: ids, in: modelContext))
        case .playlist:
            persistentModelIDs.formUnion(Playlist.persistentModelIDs(for: ids, in: modelContext))
        default:
            fatalError()
        }
    }
    return persistentModelIDs
}
