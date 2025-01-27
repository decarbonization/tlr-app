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

@Observable final class WorkCoordinator {
    init() {
        _workInProgress = .init(initialState: [])
    }
    
    private let _workInProgress: OSAllocatedUnfairLock<[Progress]>
    
    var workInProgress: [Progress] {
        access(keyPath: \.workInProgress)
        return _workInProgress.withLock { workInProgress in
            [Progress](workInProgress)
        }
    }
    
    func perform<R>(_ item: some WorkItem<R>) -> Task<R, any Error> {
        let itemProgress = item.makeConfiguredProgress()
        _workInProgress.withLock { workInProgress in
            workInProgress.append(itemProgress)
        }
        let workTask = Task(priority: .background) {
            defer {
                self.withMutation(keyPath: \.workInProgress) {
                    self._workInProgress.withLock { workInProgress in
                        guard let toRemove = workInProgress.firstIndex(of: itemProgress) else {
                            return
                        }
                        workInProgress.remove(at: toRemove)
                    }
                }
            }
            return try await item.perform(reportingTo: itemProgress)
        }
        itemProgress.cancellationHandler = {
            workTask.cancel()
        }
        return workTask
    }
}
