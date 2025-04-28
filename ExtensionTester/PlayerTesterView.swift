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
import SwiftUI

struct PlayerTesterView: View {
    @Environment(\.listeningRoomPlayer) private var player
    
    var body: some View {
        @Bindable var player = player
        VStack {
            Label("Player", systemImage: "music.note.list")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            HStack {
                Button {
                    Task {
                        try await player.pause()
                    }
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .disabled(player.playbackState != .playing)
                
                Button {
                    Task {
                        try await player.resume()
                    }
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .disabled(player.playbackState != .paused)
                
                Button {
                    Task {
                        try await player.skipPrevious()
                    }
                } label: {
                    Label("Previous", systemImage: "backward.end.alt.fill")
                }
                .disabled(player.playingItemIndex == nil)
                
                Button {
                    Task {
                        try await player.skipNext()
                    }
                } label: {
                    Label("Next", systemImage: "forward.end.alt.fill")
                }
                .disabled(player.playingItemIndex == nil)
            }
        }
    }
}
