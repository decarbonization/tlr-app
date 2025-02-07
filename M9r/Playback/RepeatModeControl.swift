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

struct RepeatModeControl: View {
    @Environment(PlayQueue.self) private var playQueue
    
    var body: some View {
        @Bindable var playQueue = playQueue
        
        _RepeatModeControlContent(repeatMode: $playQueue.repeatMode)
    }
}

struct _RepeatModeControlContent: View {
    init(repeatMode: Binding<PlayQueue.RepeatMode>) {
        _repeatMode = repeatMode
    }
    
    @Binding private var repeatMode: PlayQueue.RepeatMode
    
    var body: some View {
        Picker(selection: $repeatMode) {
            ForEach(PlayQueue.RepeatMode.allCases, id: \.self) { repeatMode in
                _RepeatModeLabel(repeatMode: repeatMode)
                    .labelStyle(.iconOnly)
            }
        } label: {
            
        }
    }
}

private struct _RepeatModeLabel: View {
    let repeatMode: PlayQueue.RepeatMode
    
    var body: some View {
        switch repeatMode {
        case .none:
            Label("Repeat None", systemImage: "arrow.turn.down.right")
        case .all:
            Label("Repeat All", systemImage: "repeat")
        case .one:
            Label("Repeat One", systemImage: "repeat.1")
        }
    }
}

#Preview {
    @Previewable @State var repeatMode = PlayQueue.RepeatMode.none
    
    _RepeatModeControlContent(repeatMode: $repeatMode)
}
