/*
 * MIT No Attribution
 *
 * Copyright 2025 Peter "Kevin" Contreras
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import os

public final class AsyncSubscriber: Sendable {
    public init() {
        _nextID = .init(initialState: 0)
        _tasks = .init(initialState: [:])
    }
    
    deinit {
        deactivateAll()
    }
    
    private let _nextID: OSAllocatedUnfairLock<UInt64>
    private let _tasks: OSAllocatedUnfairLock<[UInt64: Task<Void, any Error>]>
    
    public func activate<T: Sendable, E: Error>(consuming source: some (AsyncSequence<T, E> & Sendable),
                                                with observer: @escaping @Sendable (T, inout Bool) async -> Void) {
        let ourID = _nextID.withLock { nextID in
            let ourID = nextID
            nextID += 1
            return ourID
        }
        let newTask = Task.detached {
            for try await next in source {
                guard !Task.isCancelled else {
                    break
                }
                var stop = false
                await observer(next, &stop)
                if stop {
                    break
                }
            }
        }
        _tasks.withLock { tasks in
            tasks[ourID] = newTask
        }
    }
    
    public func deactivateAll() {
        let toCancel = _tasks.withLock { tasks in
            let toCancel = Array(tasks.values)
            tasks.removeAll()
            return toCancel
        }
        for task in toCancel {
            task.cancel()
        }
    }
}
