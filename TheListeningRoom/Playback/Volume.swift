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

import SwiftUI

struct Volume: View {
    @Environment(PlayQueue.self) private var playQueue
    
    var body: some View {
        @Bindable var playQueue = playQueue
        _VolumeContent(volume: $playQueue.volume)
    }
}

struct _VolumeContent: View {
    init(volume: Binding<Float>) {
        _volume = volume
    }
    
    @Binding private var volume: Float
    @State var isPresenting = false
    
    var body: some View {
        Button {
            isPresenting.toggle()
        } label: {
            if volume == 0 {
                Label("Volume", systemImage: "speaker")
            } else if volume <= 0.3 {
                Label("Volume", systemImage: "speaker.wave.1")
            } else if volume <= 0.6 {
                Label("Volume", systemImage: "speaker.wave.2")
            } else {
                Label("Volume", systemImage: "speaker.wave.3")
            }
        }
        .popover(isPresented: $isPresenting, arrowEdge: .bottom) {
            Slider(value: $volume) {
                Text("Volume")
            } minimumValueLabel: {
                Label("Mute", systemImage: "speaker")
            } maximumValueLabel: {
                Label("Full", systemImage: "speaker.wave.3")
            }
            .labelStyle(.iconOnly)
            .labelsHidden()
            .padding()
            .frame(minWidth: 200)
        }
    }
}

#Preview {
    @Previewable @State var volume: Float = 1.0
    
    _VolumeContent(volume: $volume)
}
