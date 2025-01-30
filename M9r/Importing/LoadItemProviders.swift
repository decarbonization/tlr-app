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

import CoreTransferable
import Foundation
import os

func loadAll<T: Transferable>(_ transferableType: T.Type = T.self,
                              from itemProviders: [NSItemProvider],
                              completionHandler: @escaping @MainActor ([Result<T, any Error>], Progress) -> Void) -> Progress {
    let overallProgress = Progress(totalUnitCount: Int64(itemProviders.count))
    overallProgress.localizedDescription = NSLocalizedString("Loading…", comment: "")
    let group = DispatchGroup()
    let results = OSAllocatedUnfairLock(initialState: [Result<T, any Error>]())
    for itemProvider in itemProviders {
        group.enter()
        let progress = itemProvider.loadTransferable(type: transferableType) { result in
            results.withLock { results in
                results.append(result)
            }
            group.leave()
        }
        overallProgress.addChild(progress, withPendingUnitCount: 1)
    }
    group.notify(queue: .main) {
        MainActor.assumeIsolated {
            completionHandler(results.withLock { $0 }, overallProgress)
        }
    }
    return overallProgress
}
