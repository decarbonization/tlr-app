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
import Testing
@testable import M9r

@Suite struct ResultsTests {
    private enum FakeError: Error {
        case failed
    }
    
    @Test func mapResults() throws {
        let results: [Result<String, any Error>] = [
            .success("hello"),
            .failure(FakeError.failed),
            .success("goodbye"),
        ]
        let reversedResults = M9r.mapResults(results) { word in
            String(word.reversed())
        }
        #expect(try reversedResults[0].get() == "olleh")
        #expect(throws: FakeError.self, performing: { try reversedResults[1].get() })
        #expect(try reversedResults[2].get() == "eybdoog")
    }
    
    @Test func extractResults() {
        let results: [Result<String, any Error>] = [
            .success("hello"),
            .failure(FakeError.failed),
            .success("goodbye"),
        ]
        let (words, errors) = M9r.extractResults(results)
        #expect(words == ["hello", "goodbye"])
        #expect(errors.count == 1)
        #expect(errors[0] is FakeError)
    }
}
