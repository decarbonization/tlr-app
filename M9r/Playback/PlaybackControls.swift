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
import SFBAudioEngine

struct PlaybackControls: View {
    @Environment(PlayQueue.self) var playQueue
    @Environment(\.library) var library
    
    var body: some View {
        HStack {
            Button {
                try! playQueue.previousTrack()
            } label: {
                Label("Previous Track", systemImage: "backward.end.alt.fill")
            }
            .disabled(!playQueue.canSkipPreviousTrack)
            .keyboardShortcut(.leftArrow, modifiers: .command)
            Button {
                switch playQueue.playbackState {
                case .stopped:
                    try! playQueue.play(library.allSongs)
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
            .keyboardShortcut(.space)
            Button {
                try! playQueue.nextTrack()
            } label: {
                Label("Previous Track", systemImage: "forward.end.alt.fill")
            }
            .disabled(!playQueue.canSkipNextTrack)
            .keyboardShortcut(.rightArrow, modifiers: .command)
        }
        .labelStyle(.iconOnly)
    }
}
