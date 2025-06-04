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

import TheListeningRoomExtensionSDK
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TheListeningRoomApp.Delegate.self) private var appDelegate
    
    var body: some View {
        HSplitView {
            LibraryTabView()
            PlaybackTabView()
                .frame(minWidth: 100, idealWidth: 200, maxWidth: 250)
        }
        .libraryRevealable()
        .preferredColorScheme(.dark)
        .task {
            for await urls in appDelegate.openURLs {
                Library.performChanges(inContainerOf: modelContext) { library in
                    let addResults = await library.findAndAddSongs(fromContentsOf: urls.map { .success($0) })
                    for case .failure(let error) in addResults {
                        await AppNotificationCenter.global.present(ListeningRoomNotification(presenting: error))
                    }
                } catching: { error in
                    await AppNotificationCenter.global.present(ListeningRoomNotification(presenting: error))
                }
            }
        }
    }
}
