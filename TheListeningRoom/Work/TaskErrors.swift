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

import os
import SwiftUI

@Observable final class TaskErrors: Sendable {
    static let all = TaskErrors()
    
    init() {
        _presented = .init(initialState: [])
    }
    
    private let _presented: OSAllocatedUnfairLock<[PresentableError]>
    
    var presented: [PresentableError] {
        access(keyPath: \.presented)
        return _presented.withLock { $0 }
    }
    
    func present(_ errors: some Sequence<any Error>) {
        withMutation(keyPath: \.presented) {
            _presented.withLock { presented in
                presented.append(contentsOf: errors.lazy.map { PresentableError(wrapping: $0) })
            }
        }
    }
    
    func present(_ error: any Error) {
        present(CollectionOfOne(error))
    }
    
    func present(_ results: some Sequence<Result<some Any, any Error>>) {
        present(results.lazy.compactMap { result in
            guard case .failure(let error) = result else {
                return nil
            }
            return error
        })
    }
    
    func clearPresented() {
        withMutation(keyPath: \.presented) {
            _presented.withLock { presented in
                presented.removeAll()
            }
        }
    }
    
    func clearPresented(matching ids: Set<PresentableError.ID>) {
        withMutation(keyPath: \.presented) {
            _presented.withLock { presented in
                presented.removeAll(where: { ids.contains($0.id) })
            }
        }
    }
}

struct PresentableError: Identifiable, Error, CustomDebugStringConvertible {
    init(wrapping error: any Error) {
        id = ObjectIdentifier(error as NSError)
        capturedAt = Date()
        if let error = error as? PresentableError {
            unwrap = error.unwrap
        } else {
            unwrap = error
        }
    }
    
    let id: ObjectIdentifier
    let capturedAt: Date
    let unwrap: any Error
    
    var localizedDescription: String {
        unwrap.localizedDescription
    }
    
    var debugDescription: String {
        "\(unwrap)"
    }
}
