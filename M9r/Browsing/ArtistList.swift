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

import SwiftUI
import SwiftData

struct ArtistList: View {
    init(filter: Predicate<Artist>? = nil) {
        _artists = .init(filter: filter, sort: \Artist.name)
    }
    
    @Query(sort: \Artist.name) var artists: [Artist]
    @Environment(PlayQueue.self) private var playQueue
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List(artists) { artist in
            NavigationLink(artist.name) {
                AlbumList(filter: #Predicate { [artistID = artist.id] in $0.artist?.persistentModelID == artistID }) {
                    NavigationLink("All Songs") {
                        DeferView {
                            SongList(filter: #Predicate { [artistID = artist.id] in $0.artist?.persistentModelID == artistID })
                                .navigationTitle(artist.name)
                        }
                    }
                    .buttonStyle(.borderless)
                    .padding(.all.subtracting(.bottom))
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .navigationTitle(artist.name)
            }
            .onDrag {
                let itemProvider = NSItemProvider()
                itemProvider.register(LibraryItem(from: artist))
                return itemProvider
            }
            .contextMenu {
                ItemContextMenuContent(selection: [artist.id])
            }
        }
        .onDropOfImportableItems()
    }
}
