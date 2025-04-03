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
    @Test func replaceChangesItemIDsCompletely() async throws {
        let subject = Queue<String, Void>()
        subject.append(contentsOf: ["goglga", "foblazle"])
        
        let newItemIDs = ["pwba", "ojwer", "gdsin", "shoboing"]
        subject.replace(withContentsOf: newItemIDs)
        
        #expect(subject.itemIDs == ["pwba", "ojwer", "gdsin", "shoboing"])
    }
    
    @Test func replaceShufflesItemIDsWhenAppropriate() async throws {
        let subject = Queue<String, Void>()
        subject.isShuffleEnabled = true
        
        let newItemIDs = ["pwba", "ojwer", "gdsin", "shoboing"]
        var confirmedShuffle = false
        for _ in 0 ..< 5 {
            subject.replace(withContentsOf: newItemIDs)
            if subject.itemIDs != ["pwba", "ojwer", "gdsin", "shoboing"] {
                confirmedShuffle = true
                break
            }
        }
        #expect(confirmedShuffle, "PlaybackQueue did not shuffle item IDs after 5 tries")
        #expect(subject.itemIDs.contains("pwba"))
        #expect(subject.itemIDs.contains("ojwer"))
        #expect(subject.itemIDs.contains("gdsin"))
        #expect(subject.itemIDs.contains("shoboing"))
    }
    
    @Test func insertPutsItemIDsSequentially() async throws {
        let subject = Queue<String, Void>()
        subject.append(contentsOf: ["goglga", "foblazle"])
        
        let newItemIDs = ["pwba", "ojwer", "gdsin", "shoboing"]
        subject.insert(contentsOf: newItemIDs, at: 1)
        
        #expect(subject.itemIDs == ["goglga", "pwba", "ojwer", "gdsin", "shoboing", "foblazle"])
    }
    
    @Test func insertHandlesDuplicateItemIDs() async throws {
        let subject = Queue<String, Void>()
        subject.append(contentsOf: ["goglga", "gdsin", "foblazle", "shoboing"])
        
        let newItemIDs = ["pwba", "ojwer", "gdsin", "shoboing"]
        subject.insert(contentsOf: newItemIDs, at: 1)
        
        #expect(subject.itemIDs == ["goglga", "pwba", "ojwer", "gdsin", "foblazle", "shoboing"])
    }
    
    @Test func appendPutsItemIDsAtEnd() async throws {
        let subject = Queue<String, Void>()
        
        let newItemIDs = ["foblazle", "shoboing", "goglga"]
        subject.append(contentsOf: newItemIDs)
        
        #expect(subject.itemIDs == ["foblazle", "shoboing", "goglga"])
    }

    @Test func appendHandlesDuplicateItemIDs() async throws {
        let subject = Queue<String, Void>()
        
        let newItemIDs = ["foblazle", "shoboing", "goglga"]
        subject.append(contentsOf: newItemIDs)
        
        #expect(subject.itemIDs == ["foblazle", "shoboing", "goglga"])
        
        let moreItems = ["lkposk", "foblazle"]
        subject.append(contentsOf: moreItems)
        
        #expect(subject.itemIDs == ["foblazle", "shoboing", "goglga", "lkposk"])
    }
    
    @Test func removeWithIDsDropsMatchingItemIDs() async throws {
        let subject = Queue<String, Void>()
        
        let newItemIDs = ["foblazle", "shoboing", "goglga", "lkposk"]
        subject.append(contentsOf: newItemIDs)
        
        subject.remove(withIDs: ["foblazle", "goglga"])
        
        #expect(subject.itemIDs == ["shoboing", "lkposk"])
    }
    
    @Test func removeAtOffsetsDropsSpecifiedItemIDs() async throws {
        let subject = Queue<String, Void>()
        
        let newItemIDs = ["foblazle", "shoboing", "goglga", "lkposk"]
        subject.append(contentsOf: newItemIDs)
        
        subject.remove(atOffsets: [1, 3])
        
        #expect(subject.itemIDs == ["foblazle", "goglga"])
    }
    
    @Test func moveBeforeOffsets() async throws {
        let subject = Queue<String, Void>()
        
        let newItemIDs = ["foblazle", "shoboing", "goglga", "lkposk", "pwba", "ojwer", "gdsin"]
        subject.append(contentsOf: newItemIDs)
        
        subject.move(fromOffsets: [2, 4, 6], toOffset: 1)
        
        #expect(subject.itemIDs == ["foblazle", "goglga", "pwba", "gdsin", "shoboing", "lkposk", "ojwer"])
    }
    
    @Test func moveAfterOffsets() async throws {
        let subject = Queue<String, Void>()
        
        let newItemIDs = ["foblazle", "shoboing", "goglga", "lkposk", "pwba", "ojwer", "gdsin"]
        subject.append(contentsOf: newItemIDs)
        
        subject.move(fromOffsets: [0, 2, 4], toOffset: 6)
        
        #expect(subject.itemIDs == ["shoboing", "lkposk", "ojwer", "foblazle", "goglga", "pwba", "gdsin"])
    }
    
    @Test func moveToEnd() async throws {
        let subject = Queue<String, Void>()
        
        let newItemIDs = ["foblazle", "shoboing", "goglga", "lkposk", "pwba", "ojwer", "gdsin"]
        subject.append(contentsOf: newItemIDs)
        
        subject.move(fromOffsets: [0, 2, 4], toOffset: 7)
        
        #expect(subject.itemIDs == ["shoboing", "lkposk", "ojwer", "gdsin", "foblazle", "goglga", "pwba"])
    }
    
    @Test func previousItemID() async throws {
        let subject = Queue<String, Void>()
        
        let newItemIDs = ["foblazle", "shoboing", "gdsin"]
        subject.append(contentsOf: newItemIDs)
        
        subject.repeatMode = .none
        #expect(subject.previousItemID(preceding: "shoboing") == "foblazle")
        #expect(subject.previousItemID(preceding: "foblazle") == nil)
        
        subject.repeatMode = .all
        #expect(subject.previousItemID(preceding: "foblazle") == "gdsin")
        
        subject.repeatMode = .one
        #expect(subject.previousItemID(preceding: "foblazle") == "foblazle")
        #expect(subject.previousItemID(preceding: "shoboing") == "shoboing")
    }
    
    @Test func nextItemID() async throws {
        let subject = Queue<String, Void>()
        
        let newItemIDs = ["foblazle", "shoboing", "gdsin"]
        subject.append(contentsOf: newItemIDs)
        
        subject.repeatMode = .none
        #expect(subject.nextItemID(following: "shoboing") == "gdsin")
        #expect(subject.nextItemID(following: "gdsin") == nil)
        
        subject.repeatMode = .all
        #expect(subject.nextItemID(following: "gdsin") == "foblazle")
        
        subject.repeatMode = .one
        #expect(subject.nextItemID(following: "foblazle") == "foblazle")
        #expect(subject.nextItemID(following: "shoboing") == "shoboing")
    }
}
