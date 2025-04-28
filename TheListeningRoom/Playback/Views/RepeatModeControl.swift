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

struct RepeatModeControl: View {
    init(repeatMode: Binding<ListeningRoomRepeatMode>) {
        _repeatMode = repeatMode
    }
    
    @Binding private var repeatMode: ListeningRoomRepeatMode
    
    var body: some View {
        Button {
            let allModes = ListeningRoomRepeatMode.allCases
            let nextIndex = allModes.index(after: allModes.firstIndex(of: repeatMode)!)
            if nextIndex < allModes.endIndex {
                repeatMode = allModes[nextIndex]
            } else {
                repeatMode = allModes[allModes.startIndex]
            }
        } label: {
            switch repeatMode {
            case .none:
                Label("Repeat None", systemImage: "repeat")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.primary)
                    .opacity(0.6)
            case .all:
                Label("Repeat None", systemImage: "repeat")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color.accentColor)
            case .one:
                Label("Repeat None", systemImage: "repeat.1")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

#Preview {
    @Previewable @State var repeatMode = ListeningRoomRepeatMode.none
    
    RepeatModeControl(repeatMode: $repeatMode)
}
