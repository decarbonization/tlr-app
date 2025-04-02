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

import Foundation
import OrderedCollections
import os

@Observable final class PlaybackQueue<ItemID: Hashable & Sendable> {
    enum RepeatMode: CaseIterable, Equatable, Codable {
        case none
        case all
        case one
    }
    
    init() {
        _modes = .init(initialState: (repeat: .none, shuffle: false))
        _itemIDs = .init(initialState: OrderedSet<ItemID>())
    }
    
    private let _modes: OSAllocatedUnfairLock<(repeat: RepeatMode, shuffle: Bool)>
    private let _itemIDs: OSAllocatedUnfairLock<OrderedSet<ItemID>>
    
    private func _mutateItemIDs<R>(changes: @Sendable (inout OrderedSet<ItemID>) throws -> R) rethrows -> R {
        try withMutation(keyPath: \.itemIDs) {
            try _itemIDs.withLock(changes)
        }
    }
    
    var itemIDs: OrderedSet<ItemID> {
        access(keyPath: \.itemIDs)
        return _itemIDs.withLock { $0 }
    }
    
    func containsItem(withID itemID: ItemID) -> Bool {
        _itemIDs.withLock { itemIDs in
            itemIDs.contains(itemID)
        }
    }
    
    // MARK: - Modes
    
    var repeatMode: RepeatMode {
        get {
            access(keyPath: \.repeatMode)
            
            return _modes.withLock { modes in
                modes.repeat
            }
        }
        set {
            withMutation(keyPath: \.repeatMode) {
                _modes.withLock { modes in
                    modes.repeat = newValue
                }
            }
        }
    }
    
    var isShuffleEnabled: Bool {
        get {
            access(keyPath: \.isShuffleEnabled)
            
            return _modes.withLock { modes in
                modes.shuffle
            }
        }
        set {
            withMutation(keyPath: \.isShuffleEnabled) {
                _modes.withLock { modes in
                    modes.shuffle = newValue
                }
            }
        }
    }
    
    // MARK: - Adding
    
    func replace(withContentsOf newItems: some Sequence<ItemID>) {
        _mutateItemIDs { itemIDs in
            itemIDs.removeAll(keepingCapacity: true)
            itemIDs.append(contentsOf: newItems)
            if isShuffleEnabled {
                itemIDs.shuffle()
            }
        }
    }
    
    func insert(contentsOf newItems: some Sequence<ItemID>, at index: Int) {
        _mutateItemIDs { itemsIDs in
            var nextIndex = index
            for newItem in newItems {
                let (_, index) = itemsIDs.insert(newItem, at: nextIndex)
                if index == nextIndex {
                    nextIndex += 1
                }
            }
        }
    }
    
    func append(contentsOf newItems: some Sequence<ItemID>) {
        _mutateItemIDs { itemIDs in
            itemIDs.append(contentsOf: newItems)
        }
    }
    
    // MARK: - Moves & Deletes
    
    func remove(atOffsets offsets: IndexSet) {
        _mutateItemIDs { itemIDs in
            for offset in offsets.reversed() {
                itemIDs.remove(at: offset)
            }
        }
    }
    
    func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        _mutateItemIDs { itemIDs in
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
    }
    
    // MARK: - Sequential Playback
    
    func previousItemID(preceding itemID: ItemID) -> ItemID? {
        _itemIDs.withLock { itemIDs in
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
    }
    
    func nextItemID(following itemID: ItemID) -> ItemID? {
        _itemIDs.withLock { itemIDs in
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
}
