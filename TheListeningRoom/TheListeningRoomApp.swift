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

import AsyncAlgorithms
import SwiftData
import SwiftUI

@main
struct TheListeningRoomApp: App {
    @Observable final class Delegate: NSObject, NSApplicationDelegate {
        // NOTE: There is probably a better way to handle incoming files,
        //       but SwiftUI was only propagating the first file URL,
        //       so here we are with a nasty delegate adapter.
        
        let openURLs = AsyncChannel<[URL]>()
        
        func application(_ application: NSApplication, open urls: [URL]) {
            Task {
                await openURLs.send(urls)
            }
        }
    }
    
    init() {
        _modelContext = .init(wrappedValue: ModelContext(makeAppModelContainer()))
        _player = .init(wrappedValue: Player(modelContext: _modelContext.wrappedValue))
    }
    
    @State private var modelContext: ModelContext
    @State private var player: Player
    @State private var playQueue = PlayQueue()
    @NSApplicationDelegateAdaptor private var appDelegate: Delegate
    
    var body: some Scene {
        Window("Library", id: "library") {
            ContentView()
        }
        .environment(player)
        .environment(playQueue)
        .modelContext(modelContext)
        .commands {
            MainMenu(playQueue: playQueue,
                     modelContext: modelContext)
        }
        Settings {
            SettingsView()
                .environment(player)
                .environment(playQueue)
                .modelContext(modelContext)
        }
    }
}
