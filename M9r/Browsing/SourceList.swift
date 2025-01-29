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

struct SourceList: View {
    @Environment(Tasks.self) private var tasks
    
    var body: some View {
        List {
            Section("Library") {
                NavigationLink {
                    ArtistList()
                } label: {
                    Label("All Artists", systemImage: "music.microphone")
                }
                NavigationLink {
                    AlbumList()
                } label: {
                    Label("All Albums", systemImage: "square.stack")
                }
                NavigationLink {
                    SongList()
                } label: {
                    Label("All Songs", systemImage: "music.note")
                }
                if !tasks.inProgress.isEmpty {
                    NavigationLink {
                        TaskList()
                    } label: {
                        Label("Tasks", systemImage: "inset.filled.circle")
                    }
                }
            }
            Section("Playlists") {
                
            }
        }
        .listStyle(.sidebar)
    }
}
