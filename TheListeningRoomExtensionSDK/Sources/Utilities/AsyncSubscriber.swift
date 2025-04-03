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
        _task = .init(initialState: nil)
    }
    
    deinit {
        unsubscribe()
    }
    
    private let _task: OSAllocatedUnfairLock<Task<Void, Never>?>
    
    public func subscribe<E: Sendable>(to source: some (AsyncSequence<E, Never> & Sendable),
                                       observe: @escaping @Sendable (E) async -> Void) {
        let newTask = Task.detached {
            for await next in source {
                guard !Task.isCancelled else {
                    break
                }
                await observe(next)
            }
        }
        _task.withLock { task in
            task?.cancel()
            task = newTask
        }
    }
    
    public func unsubscribe() {
        _task.withLock { task in
            task?.cancel()
            task = nil
        }
    }
}
