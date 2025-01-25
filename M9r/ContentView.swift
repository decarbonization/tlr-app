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

import SwiftData
import SwiftUI

struct ContentView: View {
    @State var isPresentingQueue = false
    
    var body: some View {
        NavigationSplitView {
            List {
                Section("Library") {
                    NavigationLink(value: ArtistsDestination.all) {
                        Label("All Artists", systemImage: "music.microphone")
                    }
                    NavigationLink(value: AlbumsDestination.all) {
                        Label("All Albums", systemImage: "square.stack")
                    }
                    NavigationLink(value: SongsDestination.all) {
                        Label("All Songs", systemImage: "music.note")
                    }
                }
                Section("Playlists") {
                    
                }
            }
            .listStyle(.sidebar)
            .allNavigationDestinations
        } detail: {
            NavigationStack {
                VStack {
                    Text("No Selection")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }
            }
            .allNavigationDestinations
        }
        .toolbar {
            NowPlaying()
            PlaybackControls()
            Button("Queue") {
                isPresentingQueue = true
            }
            .popover(isPresented: $isPresentingQueue) {
                QueueList()
            }
        }
    }
}
