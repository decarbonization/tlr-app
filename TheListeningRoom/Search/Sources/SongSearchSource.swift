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

struct SongSearchSource: ListeningRoomSearchSource {
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    private let modelContainer: ModelContainer
    
    func search(for query: String) async throws -> [ListeningRoomSearchResultGroup] {
        let library = Library(modelContainer: modelContainer)
        let songResults = try await library.searchSongs(with: query)
        return [
            ListeningRoomSearchResultGroup(id: .songs,
                                           title: NSLocalizedString("Songs", comment: ""),
                                           results: songResults),
        ]
    }
}

extension ListeningRoomSearchResultGroup.ID {
    fileprivate static let songs = Self(rawValue: "TheListeningRoom.songs")
}

extension Library {
    fileprivate func searchSongs(with query: String) throws -> [ListeningRoomSearchResult] {
        let whatSongs = FetchDescriptor<Song>(predicate: #Predicate {
            $0.title?.localizedStandardContains(query) == true
            || $0.artist?.name.localizedStandardContains(query) == true
            || $0.album?.title.localizedStandardContains(query) == true
        })
        let matchingSongs = try modelContext.fetch(whatSongs)
        return matchingSongs.map { song in
            ListeningRoomSearchResult(itemIDs: [song.id],
                                      artwork: song.frontCoverArtwork.map { ListeningRoomImage.artwork(id: $0.id) },
                                      primaryTitle: song.title,
                                      secondaryTitle: song.album?.title,
                                      tertiaryTitle: song.artist?.name)
        }
    }
}
