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
import os

extension Progress {
    @Observable final class Tasks: Sendable {
        static let all = Tasks()
        
        private init() {
            _active = .init(initialState: [])
        }
        
        private let _active: OSAllocatedUnfairLock<[Progress]>
        
        var active: [Progress] {
            access(keyPath: \.active)
            return _active.withLock { $0 }
        }
        
        func add(_ newProgress: Progress) {
            withMutation(keyPath: \.active) {
                _active.withLock { active in
                    active.append(newProgress)
                }
            }
        }
        
        func remove(_ oldProgress: Progress) {
            withMutation(keyPath: \.active) {
                _active.withLock { active in
                    guard let toRemove = active.firstIndex(of: oldProgress) else {
                        return
                    }
                    active.remove(at: toRemove)
                }
            }
        }
    }
    
    @discardableResult static func begin<R, E>(_ progress: () -> Progress,
                                                  task: (Progress) -> Task<R, E>) -> Task<R, E> {
        let progress = progress()
        Tasks.all.add(progress)
        let task = task(progress)
        progress.cancellationHandler = {
            task.cancel()
        }
        return task
    }
}
