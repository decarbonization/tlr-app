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

import os
import SwiftUI

extension Scene {
    @SceneBuilder func presentErrors(_ present: @escaping @MainActor ([PresentableError]) -> Void) -> some Scene {
        environment(\.presentErrors, PresentErrors(present))
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

struct PresentErrors {
    init(_ implementation: @escaping @MainActor ([PresentableError]) -> Void) {
        self.implementation = implementation
    }
    
    private let implementation: @MainActor ([PresentableError]) -> Void
    
    @MainActor func callAsFunction(_ errors: some Sequence<any Error>) {
        implementation(errors.map { PresentableError(wrapping: $0) })
    }
    
    @MainActor func callAsFunction(_ error: any Error) {
        self(CollectionOfOne(error))
    }
}

extension EnvironmentValues {
    @Entry var presentErrors = PresentErrors { errors in
        Logger().error("*** Unhandled error(s): \(errors)")
    }
}
