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

protocol ExtensionAccessibleModel: PersistentModel {
    static var nextExtensionID: String { get }
    static var extensionEntity: ListeningRoomID.Entity { get }
    var extensionID: String { get }
}

extension ExtensionAccessibleModel where Self: PersistentModel {
    static var nextExtensionID: String {
        "\(extensionEntity.name)-\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
    }
    
    static func model(for id: ListeningRoomID, in modelContext: ModelContext) -> Self? {
        guard id.entity == Self.extensionEntity else {
            return nil
        }
        let externalID = id.value
        var whatModel = FetchDescriptor<Self>(predicate: #Predicate { $0.extensionID == externalID })
        whatModel.fetchLimit = 1
        whatModel.includePendingChanges = true
        guard let results = try? modelContext.fetch(whatModel),
              results.count == 1 else {
            return nil
        }
        return results[0]
    }
    
    static func persistentModelID(for id: ListeningRoomID, in modelContext: ModelContext) -> PersistentIdentifier? {
        guard id.entity == Self.extensionEntity else {
            return nil
        }
        let externalID = id.value
        var whatModel = FetchDescriptor<Self>(predicate: #Predicate { $0.extensionID == externalID })
        whatModel.fetchLimit = 1
        whatModel.includePendingChanges = true
        guard let results = try? modelContext.fetchIdentifiers(whatModel),
              results.count == 1 else {
            return nil
        }
        return results[0]
    }
    
    var extensionID: ListeningRoomID {
        ListeningRoomID(entity: Self.extensionEntity, value: self.extensionID)
    }
}

func extensionIDs(for ids: some Sequence<PersistentIdentifier>, in modelContext: ModelContext) -> [ListeningRoomID] {
    [ListeningRoomID](
        ids.lazy
        .compactMap { modelContext.model(for: $0) as? (any ExtensionAccessibleModel) }
        .map { $0.extensionID }
    )
}

func persistentModelIDs(for ids: some Sequence<ListeningRoomID>, in modelContext: ModelContext) -> [PersistentIdentifier] {
    // TODO: This doesn't preserve the order of the IDs
    
    var idsByEntity = [ListeningRoomID.Entity: Set<ListeningRoomID>]()
    for id in ids {
        idsByEntity[id.entity, default: []].insert(id)
    }
    
    var persistentModelIDs = [PersistentIdentifier]()
    for (entity, ids) in idsByEntity {
        do {
            func fetchIdentifiers<Model: ExtensionAccessibleModel>(of modelType: Model.Type) throws -> some Sequence<PersistentIdentifier> {
                let validExternalIDs = Set(ids.lazy.filter { $0.entity == Model.extensionEntity }.map { $0.value })
                var whatModels = FetchDescriptor<Model>(predicate: #Predicate { validExternalIDs.contains($0.extensionID) })
                whatModels.includePendingChanges = true
                return try modelContext.fetchIdentifiers(whatModels)
            }
            switch entity {
            case .song:
                persistentModelIDs.append(contentsOf: try fetchIdentifiers(of: Song.self))
            case .album:
                persistentModelIDs.append(contentsOf: try fetchIdentifiers(of: Album.self))
            case .artist:
                persistentModelIDs.append(contentsOf: try fetchIdentifiers(of: Artist.self))
            case .artwork:
                persistentModelIDs.append(contentsOf: try fetchIdentifiers(of: Artwork.self))
            case .playlist:
                persistentModelIDs.append(contentsOf: try fetchIdentifiers(of: Playlist.self))
            default:
                fatalError()
            }
        } catch {
            
        }
    }
    return persistentModelIDs
}
