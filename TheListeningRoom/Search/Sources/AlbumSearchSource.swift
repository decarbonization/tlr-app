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

struct AlbumSearchSource: ListeningRoomSearchSource {
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    private let modelContainer: ModelContainer
    
    func search(for query: String) async throws -> [ListeningRoomSearchResultGroup] {
        let library = Library(modelContainer: modelContainer)
        let albumResults = try await library.searchAlbums(with: query)
        return [
            ListeningRoomSearchResultGroup(id: .albums,
                                           title: NSLocalizedString("Albums", comment: ""),
                                           results: albumResults),
        ]
    }
}

extension ListeningRoomSearchResultGroup.ID {
    fileprivate static let albums = Self(rawValue: "TheListeningRoom.albums")
}

extension Library {
    fileprivate func searchAlbums(with query: String) throws -> [ListeningRoomSearchResult] {
        let whatAlbums = FetchDescriptor<Album>(predicate: #Predicate {
            $0.title.localizedStandardContains(query)
            || $0.artist?.name.localizedStandardContains(query) == true
        })
        let matchingAlbums = try modelContext.fetch(whatAlbums)
        return matchingAlbums.map { album in
            ListeningRoomSearchResult(id: album.extensionID,
                                      itemIDs: album.sortedSongs.map { $0.extensionID },
                                      artwork: album.songs.first?.frontCoverArtwork.map { .artwork(id: $0.extensionID) },
                                      primaryTitle: album.title,
                                      secondaryTitle: album.artist?.name)
        }
    }
}
