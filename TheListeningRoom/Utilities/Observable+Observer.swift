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
import os

extension Observable {
    func observeChanges<each R>(to properties: repeat KeyPath<Self, each R>) -> some AsyncSequence<Void, Never> {
        AsyncStream { continuation in
            let terminated = OSAllocatedUnfairLock(initialState: false)
            continuation.onTermination = { _ in
                terminated.withLock { terminated in
                    terminated = true
                }
            }
            for property in repeat each properties {
                @Sendable func observeNext() {
                    guard !terminated.withLock({ $0 }) else {
                        return
                    }
                    withObservationTracking {
                        withExtendedLifetime(self[keyPath: property]) {
                            // Do nothing.
                        }
                    } onChange: {
                        guard !terminated.withLock({ $0 }) else {
                            return
                        }
                        continuation.yield()
                        observeNext()
                    }
                }
                observeNext()
            }
        }
    }
}
