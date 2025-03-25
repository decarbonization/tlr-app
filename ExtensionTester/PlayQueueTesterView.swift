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

import ListeningRoomExtensionSDK
import SwiftUI

struct PlayQueueTesterView: View {
    @Environment(\.listeningRoomPlayQueue) private var playQueue
    
    var body: some View {
        @Bindable var playQueue = playQueue
        VStack {
            Label("Play Queue", systemImage: "music.note.list")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            HStack {
                Button {
                    Task {
                        try await playQueue.pause()
                    }
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                }
                .disabled(playQueue.playbackState != .playing)
                
                Button {
                    Task {
                        try await playQueue.resume()
                    }
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .disabled(playQueue.playbackState != .paused)
                
                Button {
                    Task {
                        try await playQueue.previousTrack()
                    }
                } label: {
                    Label("Previous", systemImage: "backward.end.alt.fill")
                }
                .disabled(!playQueue.canSkipPreviousTrack)
                
                Button {
                    Task {
                        try await playQueue.nextTrack()
                    }
                } label: {
                    Label("Next", systemImage: "forward.end.alt.fill")
                }
                .disabled(!playQueue.canSkipNextTrack)
            }
        }
    }
}
