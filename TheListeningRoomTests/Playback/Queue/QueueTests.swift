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
import Testing
@testable import TheListeningRoom

@Suite struct QueueTests {
    @Test func insertPutsItemsSequentially() async throws {
        let subject = Queue<String>()
        subject.append(contentsOf: ["goglga", "foblazle"])
        
        let newItems = ["pwba", "ojwer", "gdsin", "shoboing"]
        subject.insert(contentsOf: newItems, at: 1)
        
        #expect(subject.ordered == ["goglga", "pwba", "ojwer", "gdsin", "shoboing", "foblazle"])
    }
    
    @Test func insertHandlesDuplicateItems() async throws {
        let subject = Queue<String>()
        subject.append(contentsOf: ["goglga", "gdsin", "foblazle", "shoboing"])
        
        let newItems = ["pwba", "ojwer", "gdsin", "shoboing"]
        subject.insert(contentsOf: newItems, at: 1)
        
        #expect(subject.ordered == ["goglga", "pwba", "ojwer", "gdsin", "foblazle", "shoboing"])
    }
    
    @Test func appendPutsItemsAtEnd() async throws {
        let subject = Queue<String>()
        
        let newItems = ["foblazle", "shoboing", "goglga"]
        subject.append(contentsOf: newItems)
        
        #expect(subject.ordered == newItems)
    }

    @Test func appendHandlesDuplicateItems() async throws {
        let subject = Queue<String>()
        
        let newItems = ["foblazle", "shoboing", "goglga"]
        subject.append(contentsOf: newItems)
        
        #expect(subject.ordered == newItems)
        
        let moreItems = ["lkposk", "foblazle"]
        subject.append(contentsOf: moreItems)
        
        #expect(subject.ordered == ["foblazle", "shoboing", "goglga", "lkposk"])
    }
    
    @Test func removeDropsSpecifiedItems() async throws {
        let subject = Queue<String>()
        
        let newItems = ["foblazle", "shoboing", "goglga", "lkposk"]
        subject.append(contentsOf: newItems)
        
        subject.remove(atOffsets: [1, 3])
        
        #expect(subject.ordered == ["foblazle", "goglga"])
    }
    
    @Test func moveBeforeOffsets() async throws {
        let subject = Queue<String>()
        
        let newItems = ["foblazle", "shoboing", "goglga", "lkposk", "pwba", "ojwer", "gdsin"]
        subject.append(contentsOf: newItems)
        
        subject.move(fromOffsets: [2, 4, 6], toOffset: 1)
        
        #expect(subject.ordered == ["foblazle", "goglga", "pwba", "gdsin", "shoboing", "lkposk", "ojwer"])
    }
    
    @Test func moveAfterOffsets() async throws {
        let subject = Queue<String>()
        
        let newItems = ["foblazle", "shoboing", "goglga", "lkposk", "pwba", "ojwer", "gdsin"]
        subject.append(contentsOf: newItems)
        
        subject.move(fromOffsets: [0, 2, 4], toOffset: 6)
        
        #expect(subject.ordered == ["shoboing", "lkposk", "ojwer", "foblazle", "goglga", "pwba", "gdsin"])
    }
    
    @Test func moveToEnd() async throws {
        let subject = Queue<String>()
        
        let newItems = ["foblazle", "shoboing", "goglga", "lkposk", "pwba", "ojwer", "gdsin"]
        subject.append(contentsOf: newItems)
        
        subject.move(fromOffsets: [0, 2, 4], toOffset: 7)
        
        #expect(subject.ordered == ["shoboing", "lkposk", "ojwer", "gdsin", "foblazle", "goglga", "pwba"])
    }
}
