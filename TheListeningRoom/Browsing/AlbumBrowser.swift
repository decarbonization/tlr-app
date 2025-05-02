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

import SwiftData
import SwiftUI

struct AlbumBrowser: View {
    private enum SelectedItem: Hashable {
        case all
        case album(PersistentIdentifier)
    }
    
    init(artistID: PersistentIdentifier? = nil) {
        self.artistID = artistID
        if let artistID {
            _albums = .init(filter: #Predicate { $0.artist?.persistentModelID == artistID }, sort: \Album.title)
        } else {
            _albums = .init(sort: \Album.title)
        }
    }
    
    private let artistID: PersistentIdentifier?
    @State private var selection = SelectedItem.all
    @Query var albums: [Album]
    
    var body: some View {
        ScrollViewReader { scrollView in
            HSplitView {
                List(selection: $selection) {
                    Text("All Songs")
                        .tag(SelectedItem.all)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .allowsHitTesting(false)
                    
                    ForEach(albums) { album in
                        HStack {
                            Group {
                                if let image = album.songs.first?.artwork.first?.image {
                                    image.resizable()
                                } else {
                                    Color.gray
                                }
                            }
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 3.0))
                            Text(verbatim: album.title)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                        .tag(SelectedItem.album(album.id))
                        .allowsHitTesting(false)
                        .onDrag {
                            let itemProvider = NSItemProvider()
                            let libraryItem = LibraryItem(from: album)
                            itemProvider.register(libraryItem)
                            return itemProvider
                        }
                        .contextMenu {
                            ItemContextMenuContent(selection: [album.id])
                        }
                    }
                }
                .frame(minWidth: 100, idealWidth: 150, maxWidth: 250)
                
                VStack(alignment: .leading, spacing: 0.0) {
                    switch selection {
                    case .all:
                        SongBrowser()
                    case .album(let albumID):
                        SongBrowser(filter: #Predicate { $0.album?.persistentModelID == albumID })
                    }
                }
            }
            .revealInLibrary { itemIDs in
                if let newSelectedID = itemIDs.lazy.filter({ $0.entityName == Schema.entityName(for: Artist.self) }).first {
                    selection = .album(newSelectedID)
                    scrollView.scrollTo(newSelectedID)
                } else {
                    selection = .all
                }
            }
            .onDropOfImportableItems()
        }
    }
}
