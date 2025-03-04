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

import Foundation
import OrderedCollections
import os

@Observable final class Queue<Item: Hashable & Sendable>: Sendable {
    init() {
        _items = .init(initialState: OrderedSet<Item>())
    }
    
    private let _items: OSAllocatedUnfairLock<OrderedSet<Item>>
    
    @discardableResult func _mutateItems<R>(_ changes: @Sendable (inout OrderedSet<Item>) throws -> R) rethrows -> R {
        try withMutation(keyPath: \.ordered) {
            try _items.withLock(changes)
        }
    }
    
    var ordered: [Item] {
        access(keyPath: \.ordered)
        return _items.withLock { items in
            items.elements
        }
    }
    
    func insert(contentsOf newItems: some Sequence<Item>, at index: Int) {
        _mutateItems { items in
            var nextIndex = index
            for newItem in newItems {
                let (_, index) = items.insert(newItem, at: nextIndex)
                if index == nextIndex {
                    nextIndex += 1
                }
            }
        }
    }
    
    func append(contentsOf newItems: some Sequence<Item>) {
        _mutateItems { items in
            items.append(contentsOf: newItems)
        }
    }
    
    func remove(atOffsets offsets: IndexSet) {
        _mutateItems { items in
            for offset in offsets.reversed() {
                items.remove(at: offset)
            }
        }
    }
    
    func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        _mutateItems { items in
            var toMove = [Item]()
            toMove.reserveCapacity(offsets.count)
            for offset in offsets.reversed() {
                toMove.insert(items.remove(at: offset), at: 0)
            }
            let finalDestination = destination >= items.count ? destination - offsets.count : destination
            for (offset, item) in toMove.enumerated() {
                items.insert(item, at: finalDestination + offset)
            }
        }
    }
}
