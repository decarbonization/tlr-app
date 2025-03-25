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

import SwiftUI
import SwiftData

struct AlbumList<HeaderView: View>: View {
    init(filter: Predicate<Album>? = nil) where HeaderView == EmptyView {
        _albums = .init(filter: filter, sort: \Album.title)
        header = { EmptyView() }
    }
    
    init(filter: Predicate<Album>? = nil,
         @ViewBuilder header: @escaping () -> HeaderView) {
        _albums = .init(filter: filter, sort: \Album.title)
        self.header = header
    }
    
    @Query var albums: [Album]
    private let header: () -> HeaderView
    @Environment(PlayQueue.self) private var playQueue
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            header()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 128, maximum: 150))]) {
                ForEach(albums) { album in
                    NavigationLink {
                        DeferView {
                            SongList(filter: #Predicate { [albumID = album.id] in $0.album?.persistentModelID == albumID },
                                     sortOrder: [
                                        SortDescriptor(\Song.discNumber),
                                        SortDescriptor(\Song.trackNumber),
                                     ])
                            .navigationTitle(album.title)
                        }
                    } label: {
                        VStack {
                            Group {
                                if let image = album.songs.first?.artwork.first?.image {
                                    image.resizable()
                                } else {
                                    Color.gray
                                }
                            }
                            .frame(width: 128, height: 128)
                            .clipShape(RoundedRectangle(cornerRadius: 3.0))
                            Text(verbatim: album.title)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.borderless)
                    .onDrag {
                        let itemProvider = NSItemProvider()
                        itemProvider.register(LibraryItem(from: album))
                        return itemProvider
                    }
                    .contextMenu {
                        ItemContextMenuContent(selection: [album.id])
                    }
                }
            }
            .padding()
        }
        .background(.background)
        .onDropOfImportableItems()
    }
}
