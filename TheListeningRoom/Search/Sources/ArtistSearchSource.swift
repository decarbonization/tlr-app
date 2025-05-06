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
import TheListeningRoomExtensionSDK
import SwiftData

struct ArtistSearchSource: ListeningRoomSearchSource {
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    private let modelContainer: ModelContainer
    
    func search(for query: String) async throws -> [ListeningRoomSearchResultGroup] {
        let library = Library(modelContainer: modelContainer)
        let artistResults = try await library.searchArtists(with: query)
        return [
            ListeningRoomSearchResultGroup(id: .artists,
                                           title: NSLocalizedString("Artists", comment: ""),
                                           results: artistResults),
        ]
    }
}

extension ListeningRoomSearchResultGroup.ID {
    fileprivate static let artists = Self(rawValue: "TheListeningRoom.artists")
}

extension Library {
    fileprivate func searchArtists(with query: String) throws -> [ListeningRoomSearchResult] {
        let whatArtists = FetchDescriptor<Artist>(predicate: #Predicate {
            $0.name.localizedStandardContains(query)
        })
        let matchingArtists = try modelContext.fetch(whatArtists)
        return matchingArtists.map { artist in
            ListeningRoomSearchResult(id: artist.extensionID,
                                      itemIDs: artist.sortedSongs.map { $0.extensionID },
                                      primaryTitle: artist.name)
        }
    }
}
