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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TheListeningRoomApp.Delegate.self) private var appDelegate
    
    var body: some View {
        HSplitView {
            TabView {
                Tab("Artists", systemImage: "music.microphone") {
                    ArtistBrowser()
                }
                Tab("Albums", systemImage: "square.stack") {
                    AlbumBrowser()
                }
                Tab("Songs", systemImage: "music.note") {
                    SongBrowser()
                }
                Tab("Playlists", systemImage: "music.note.list") {
                    PlaylistBrowser()
                }
                Tab("Extensions", systemImage: "puzzlepiece.extension") {
                    ExtensionBrowser()  // NOTE: This will go away
                }
            }
            TabView {
                Tab("Old", systemImage: "list.number") {
                    QueueList()
                }
                Tab("New", systemImage: "list.number") {
                    QueueList2()
                }
            }
            .tabViewStyle(.tabBarOnly)
            .frame(minWidth: 100, idealWidth: 200, maxWidth: 250)
        }
        .preferredColorScheme(.dark)
        .task {
            for await urls in appDelegate.openURLs {
                Library.performChanges(inContainerOf: modelContext) { library in
                    let addResults = await library.findAndAddSongs(fromContentsOf: urls.map { .success($0) })
                    TaskErrors.all.present(addResults)
                } catching: { error in
                    TaskErrors.all.present(error)
                }
            }
        }
    }
}
