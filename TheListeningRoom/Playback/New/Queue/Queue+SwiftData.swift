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
import SwiftData

extension Queue where ItemID == PersistentIdentifier, Context == ModelContext {
    struct Items<Item: PersistentModel>: RandomAccessCollection {
        init(context: ModelContext,
             ids: OrderedSet<PersistentIdentifier>) {
            self.context = context
            self.ids = ids
        }
        
        private let context: ModelContext
        private let ids: OrderedSet<PersistentIdentifier>
        
        var startIndex: Int {
            ids.startIndex
        }
        
        var endIndex: Int {
            ids.endIndex
        }
        
        func index(before i: Int) -> Int {
            ids.index(before: i)
        }
        
        func index(after i: Int) -> Int {
            ids.index(after: i)
        }
        
        subscript(position: Int) -> Item {
            context.registeredModel(for: ids[position])!
        }
    }
    
    func item<Item: PersistentModel>(of modelType: Item.Type = Item.self,
                                     withID itemID: ItemID) -> Item? {
        context.registeredModel(for: itemID)
    }
    
    func items<Item: PersistentModel>(of modelType: Item.Type = Item.self) -> Items<Item> {
        Items(context: context, ids: itemIDs)
    }
}
