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

@Suite struct TaskErrorsTests {
    @Test func presentingErrors() {
        let subject = TaskErrors()
        subject.present([
            CocoaError(.fileNoSuchFile),
            URLError(.badURL),
        ] as [any Error])
        #expect(subject.presented.count == 2)
        
        subject.clearPresented()
        #expect(subject.presented.isEmpty)
    }
}
