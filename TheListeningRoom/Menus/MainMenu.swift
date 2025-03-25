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

struct MainMenu: Commands {
    init(playQueue: PlayQueue,
         modelContainer: ModelContainer) {
        self.playQueue = playQueue
        self.modelContainer = modelContainer
    }
    
    private let playQueue: PlayQueue
    private let modelContainer: ModelContainer
    @State private var isImporting = false
    
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open…") {
                isImporting = true
            }
            .keyboardShortcut("o", modifiers: .command)
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.audio, .folder], allowsMultipleSelection: true) { result in
                Library.performChanges(in: modelContainer) { library in
                    let urls = try result.get()
                    let addResults = await library.findAndAddSongs(fromContentsOf: urls.map { .success($0) })
                    TaskErrors.all.present(addResults)
                } catching: { error in
                    TaskErrors.all.present(error)
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
                do {
                    try playQueue.previousTrack()
                } catch {
                    TaskErrors.all.present(error)
                }
            } label: {
                Label("Previous Track", systemImage: "backward.end.alt.fill")
            }
            .disabled(!playQueue.canSkipPreviousTrack)
            .keyboardShortcut(.leftArrow, modifiers: .command)
            
            Button {
                switch playQueue.playbackState {
                case .stopped:
                    do {
                        try playQueue.play(playQueue.items, startingAt: 0)
                    } catch {
                        TaskErrors.all.present(error)
                    }
                case .paused:
                    playQueue.resume()
                case .playing:
                    playQueue.pause()
                @unknown default:
                    fatalError()
                }
            } label: {
                switch playQueue.playbackState {
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
            .disabled(playQueue.items.isEmpty)
            .keyboardShortcut(.space)
            
            Button {
                do {
                    try playQueue.nextTrack()
                } catch {
                    TaskErrors.all.present(error)
                }
            } label: {
                Label("Previous Track", systemImage: "forward.end.alt.fill")
            }
            .disabled(!playQueue.canSkipNextTrack)
            .keyboardShortcut(.rightArrow, modifiers: .command)
            
            Divider()
            
            Button {
                guard playQueue.volume < 1.0 else {
                    return
                }
                playQueue.volume += 0.1
            } label: {
                Label("Incrase Volume", systemImage: "speaker.wave.3")
            }
            .keyboardShortcut(.upArrow, modifiers: .command)
            
            Button {
                guard playQueue.volume > 0.0 else {
                    return
                }
                playQueue.volume -= 0.1
            } label: {
                Label("Decrease Volume", systemImage: "speaker.wave.1")
            }
            .keyboardShortcut(.downArrow, modifiers: .command)
        }
    }
}
