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

struct ArtistBrowser: View {
    private enum SelectedItem: Hashable {
        case all
        case artist(PersistentIdentifier)
    }
    
    @State private var selection = SelectedItem.all
    @Query(sort: \Artist.name) var artists: [Artist]
    
    var body: some View {
        HSplitView {
            List(selection: $selection) {
                Text("All Songs")
                    .tag(SelectedItem.all)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .allowsHitTesting(false)
                
                ForEach(artists) { artist in
                    Text(verbatim: artist.name)
                        .tag(SelectedItem.artist(artist.id))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .allowsHitTesting(false)
                        .onDrag {
                            let itemProvider = NSItemProvider()
                            itemProvider.register(LibraryItem(from: artist))
                            return itemProvider
                        }
                        .contextMenu {
                            ItemContextMenuContent(selection: [artist.id])
                        }
                }
            }
            .frame(minWidth: 100, idealWidth: 150, maxWidth: 250)
            
            VStack(alignment: .leading, spacing: 0.0) {
                switch selection {
                case .all:
                    SongBrowser()
                case .artist(let artistID):
                    AlbumBrowser(artistID: artistID)
                }
            }
        }
        .onDropOfImportableItems()
    }
}
