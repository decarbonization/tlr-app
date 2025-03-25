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

@Suite struct CollectionIndicesTests {
    @Test func indexed() {
        let numberWords = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
        #expect(numberWords.indexed.startIndex == numberWords.startIndex)
        #expect(numberWords.indexed.endIndex == numberWords.endIndex)
        #expect(numberWords.indexed.map(\.index) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(numberWords.indexed.map(\.element) == numberWords)
        
        let numberWordsSlice = numberWords[1 ... 5]
        #expect(numberWordsSlice.indexed.startIndex == numberWordsSlice.startIndex)
        #expect(numberWordsSlice.indexed.endIndex == numberWordsSlice.endIndex)
        #expect(numberWordsSlice.indexed.map(\.index) == [1, 2, 3, 4, 5])
        #expect(numberWordsSlice.indexed.map(\.element) == [String](numberWordsSlice))
    }
}
