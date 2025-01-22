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

struct QueueList: View {
    @Environment(PlayQueue.self) var playQueue
    @State private var selectedItems = Set<LibraryID>()
    
    var body: some View {
        @Bindable var playQueue = playQueue
        
        List(playQueue.items, selection: $selectedItems) { item in
            let position = playQueue.relativeItemPosition(item)
            Text(verbatim: item.title ?? item.file.lastPathComponent)
                .foregroundStyle(
                    position == .orderedSame ? .primary :
                    position == .orderedAscending ? .tertiary
                    : .secondary
                )
        }
        .contextMenu(forSelectionType: LibraryID.self) { selection in
            
        } primaryAction: { selection in
            guard let songID = selection.first,
                  let toPlay = playQueue.items.firstIndex(where: { $0.id == songID }) else {
                return
            }
            try! playQueue.play(playQueue.items, startingAt: toPlay)
        }
    }
}
