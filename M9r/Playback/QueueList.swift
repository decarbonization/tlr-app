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

import SwiftData
import SwiftUI

struct QueueList: View {
    @Environment(PlayQueue.self) var playQueue
    @State private var selectedItems = Set<PersistentIdentifier>()
    
    var body: some View {
        @Bindable var playQueue = playQueue
        
        VStack(spacing: 0) {
            List(selection: $selectedItems) {
                ForEach(playQueue.items) { item in
                    let position = playQueue.relativeItemPosition(item)
                    Text(verbatim: item.title ?? "")
                        .foregroundStyle(
                            position == .orderedSame ? .primary :
                                position == .orderedAscending ? .tertiary
                            : .secondary
                        )
                }
                .onDelete { toRemove in
                    playQueue.removeItems(atOffsets: toRemove)
                }
                .onMove { source, destination in
                    playQueue.moveItems(fromOffsets: source, toOffset: destination)
                }
            }
            .contextMenu(forSelectionType: PersistentIdentifier.self) { selection in
                
            } primaryAction: { selection in
                guard let songID = selection.first,
                      let toPlay = playQueue.items.firstIndex(where: { $0.id == songID }) else {
                    return
                }
                try! playQueue.play(playQueue.items, startingAt: toPlay)
            }
            NowPlaying()
        }
    }
}
