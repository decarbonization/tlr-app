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
import Foundation
import OrderedCollections
import os

@Observable final class Queue<ItemID: Hashable, Context> {
    init(context: Context) {
        self.context = context
        self.itemIDs = []
        self.repeatMode = .none
        self.isShuffleEnabled = false
    }
    
    convenience init() where Context == Void {
        self.init(context: ())
    }
    
    let context: Context
    private(set) var itemIDs: OrderedSet<ItemID>
    
    // MARK: - Modes
    
    var repeatMode: ListeningRoomRepeatMode
    var isShuffleEnabled: Bool
    
    // MARK: - Adding
    
    func replace(withContentsOf newItemsIDs: some Sequence<ItemID>,
                 pinning nextItemID: ItemID? = nil) {
        itemIDs.removeAll(keepingCapacity: true)
        if isShuffleEnabled {
            for newItemID in newItemsIDs {
                guard newItemID != nextItemID else {
                    continue
                }
                let shuffledIndex = Int.random(in: itemIDs.startIndex ... itemIDs.endIndex)
                itemIDs.insert(newItemID, at: shuffledIndex)
            }
            if let nextItemID {
                itemIDs.insert(nextItemID, at: 0)
            }
        } else {
            itemIDs.append(contentsOf: newItemsIDs)
        }
    }
    
    func insert(contentsOf newItems: some Sequence<ItemID>, at index: Int) {
        var nextIndex = index
        for newItem in newItems {
            let (_, index) = itemIDs.insert(newItem, at: nextIndex)
            if index == nextIndex {
                nextIndex += 1
            }
        }
    }
    
    func append(contentsOf newItems: some Sequence<ItemID>) {
        itemIDs.append(contentsOf: newItems)
    }
    
    // MARK: - Moves & Deletes
    
    func remove(withIDs itemIDsToRemove: Set<ItemID>) {
        itemIDs.removeAll { itemID in
            itemIDsToRemove.contains(itemID)
        }
    }
    
    func remove(atOffsets offsets: IndexSet) {
        for offset in offsets.reversed() {
            itemIDs.remove(at: offset)
        }
    }
    
    func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        var toMove = [ItemID]()
        toMove.reserveCapacity(offsets.count)
        for offset in offsets.reversed() {
            toMove.insert(itemIDs.remove(at: offset), at: 0)
        }
        let finalDestination = destination >= itemIDs.count ? destination - offsets.count : destination
        for (offset, itemID) in toMove.enumerated() {
            itemIDs.insert(itemID, at: finalDestination + offset)
        }
    }
    
    // MARK: - Sequential Playback
    
    func previousItemID(preceding itemID: ItemID) -> ItemID? {
        switch repeatMode {
        case .none:
            guard let playingIndex = itemIDs.firstIndex(of: itemID) else {
                return nil
            }
            if playingIndex > 0 {
                return itemIDs[playingIndex - 1]
            } else {
                return nil
            }
        case .all:
            guard let playingIndex = itemIDs.firstIndex(of: itemID) else {
                return nil
            }
            if playingIndex > 0 {
                return itemIDs[playingIndex - 1]
            } else {
                return itemIDs[itemIDs.count - 1]
            }
        case .one:
            return itemID
        }
    }
    
    func nextItemID(following itemID: ItemID) -> ItemID? {
        switch repeatMode {
        case .none:
            guard let playingIndex = itemIDs.firstIndex(of: itemID) else {
                return nil
            }
            if playingIndex < (itemIDs.count - 1) {
                return itemIDs[playingIndex + 1]
            } else {
                return nil
            }
        case .all:
            guard let playingIndex = itemIDs.firstIndex(of: itemID) else {
                return nil
            }
            if playingIndex < (itemIDs.count - 1) {
                return itemIDs[playingIndex + 1]
            } else {
                return itemIDs[0]
            }
        case .one:
            return itemID
        }
    }
}
