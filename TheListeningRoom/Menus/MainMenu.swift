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

struct MainMenu: Commands {
    init(player: Player,
         modelContext: ModelContext) {
        self.player = player
        self.modelContext = modelContext
    }
    
    private let player: Player
    private let modelContext: ModelContext
    @State private var isImporting = false
    
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open…") {
                isImporting = true
            }
            .keyboardShortcut("o", modifiers: .command)
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.audio, .folder], allowsMultipleSelection: true) { result in
                Library.performChanges(inContainerOf: modelContext) { library in
                    let urls = try result.get()
                    let addResults = await library.findAndAddSongs(fromContentsOf: urls.map { .success($0) })
                    for case .failure(let error) in addResults {
                        await AppNotificationCenter.global.present(ListeningRoomNotification(presenting: error))
                    }
                } catching: { error in
                    await AppNotificationCenter.global.present(ListeningRoomNotification(presenting: error))
                }
            }
        }
        CommandGroup(after: .pasteboard) {
            Button("Delete Selection") {
                NSApp.sendAction(NSSelectorFromString("delete:"), to: nil, from: nil)
            }
            .keyboardShortcut(.delete, modifiers: .command)
        }
        CommandMenu("Controls") {
            Button {
                Task {
                    do {
                        try await player.skipPrevious()
                    } catch {
                        AppNotificationCenter.global.present(ListeningRoomNotification(presenting: error))
                    }
                }
            } label: {
                Label("Previous Track", systemImage: "backward.end.alt.fill")
            }
            .disabled(player.playingItem == nil)
            .keyboardShortcut(.leftArrow, modifiers: .command)
            
            Button {
                Task {
                    switch player.playbackState {
                    case .stopped:
                        do {
                            guard let firstItem = player.queue.itemIDs.first else {
                                return
                            }
                            try await player.playItem(withID: firstItem)
                        } catch {
                            AppNotificationCenter.global.present(ListeningRoomNotification(presenting: error))
                        }
                    case .paused:
                        try await player.resume()
                    case .playing:
                        try await player.pause()
                    @unknown default:
                        fatalError()
                    }
                }
            } label: {
                switch player.playbackState {
                case .stopped:
                    Label("Play", systemImage: "play.fill")
                case .paused:
                    Label("Resume", systemImage: "play.fill")
                case .playing:
                    Label("Pause", systemImage: "pause.fill")
                @unknown default:
                    EmptyView()
                }
            }
            .disabled(player.queue.itemIDs.isEmpty)
            .keyboardShortcut(.space)
            
            Button {
                Task {
                    do {
                        try await player.skipNext()
                    } catch {
                        AppNotificationCenter.global.present(ListeningRoomNotification(presenting: error))
                    }
                }
            } label: {
                Label("Next Track", systemImage: "forward.end.alt.fill")
            }
            .disabled(player.playingItem == nil)
            .keyboardShortcut(.rightArrow, modifiers: .command)
            
            Divider()
            
            Button {
                guard player.volume < 1.0 else {
                    return
                }
                player.volume += 0.1
            } label: {
                Label("Incrase Volume", systemImage: "speaker.wave.3")
            }
            .keyboardShortcut(.upArrow, modifiers: .command)
            
            Button {
                guard player.volume > 0.0 else {
                    return
                }
                player.volume -= 0.1
            } label: {
                Label("Decrease Volume", systemImage: "speaker.wave.1")
            }
            .keyboardShortcut(.downArrow, modifiers: .command)
        }
    }
}
