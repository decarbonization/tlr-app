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

@Observable final class PendingTasks: Sendable {
    @TaskLocal static var current = PendingTasks()
    
    private init() {
        _inProgress = .init(initialState: [])
    }
    
    private var _inProgress: OSAllocatedUnfairLock<[Progress]>
    
    var inProgress: [Progress] {
        access(keyPath: \.inProgress)
        return _inProgress.withLock { inProgress in
            [Progress](inProgress)
        }
    }
    
    func start<R>(totalUnitCount: Int,
                  localizedDescription: String,
                  operation: @escaping @Sendable (Progress) async throws -> R) async throws -> R {
        let progress = Progress(totalUnitCount: Int64(totalUnitCount))
        progress.isCancellable = true
        progress.localizedDescription = localizedDescription
        withMutation(keyPath: \.inProgress) {
            _inProgress.withLock { inProgress in
                inProgress.append(progress)
            }
        }
        defer {
            withMutation(keyPath: \.inProgress) {
                _inProgress.withLock { inProgress in
                    guard let toRemove = inProgress.firstIndex(of: progress) else {
                        return
                    }
                    inProgress.remove(at: toRemove)
                }
            }
        }
        let task = Task(priority: .background) {
            try await withTaskCancellationHandler {
                try await operation(progress)
            } onCancel: {
                progress.cancel()
            }
        }
        progress.cancellationHandler = {
            task.cancel()
        }
        return try await task.value
    }
}
