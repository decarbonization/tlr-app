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

extension PlaybackQueue where ItemID == PersistentIdentifier {
    struct Items<Item: PersistentModel>: RandomAccessCollection {
        init(modelContext: ModelContext,
             ids: OrderedSet<PersistentIdentifier>) {
            self.modelContext = modelContext
            self.ids = ids
        }
        
        private let modelContext: ModelContext
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
            modelContext.registeredModel(for: ids[position])!
        }
    }
    
    func items<Item: PersistentModel>(of modelType: Item.Type = Item.self,
                                      in modelContext: ModelContext) -> Items<Item> {
        Items(modelContext: modelContext, ids: itemIDs)
    }
}
