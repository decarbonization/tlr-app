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

extension Collection {
    var indexed: CollectionWithIndices<Self> {
        CollectionWithIndices(wrapping: self)
    }
}

struct CollectionWithIndices<Base: Collection>: Collection {
    init(wrapping base: Base) {
        self.base = base
    }
    
    private var base: Base
    
    var startIndex: Base.Index {
        base.startIndex
    }
    
    var endIndex: Base.Index {
        base.endIndex
    }
    
    func index(after i: Base.Index) -> Base.Index {
        base.index(after: i)
    }
    
    subscript(position: Base.Index) -> (element: Base.Element, index: Base.Index) {
        (element: base[position], index: position)
    }
}

extension CollectionWithIndices: BidirectionalCollection where Base: BidirectionalCollection {
    func index(before i: Base.Index) -> Base.Index {
        base.index(before: i)
    }
}

extension CollectionWithIndices: RandomAccessCollection where Base: RandomAccessCollection {
}
