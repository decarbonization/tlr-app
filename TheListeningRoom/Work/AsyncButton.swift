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

import SwiftUI

struct AsyncButton<Label: View>: View {
    init(action: @escaping @MainActor () async throws -> Void,
         @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }
    
    private let action: @MainActor () async throws -> Void
    private let label: () -> Label
    @State private var pendingTask: Task<Void, Never>?
    @State private var isPresentingError = false
    @State private var presentedError: (any Error)?
    
    var body: some View {
        Button {
            guard pendingTask == nil else {
                return
            }
            pendingTask = Task(priority: .userInitiated) {
                defer {
                    pendingTask = nil
                }
                do {
                    try await action()
                } catch {
                    TaskErrors.all.present(error)
                }
            }
        } label: {
            ZStack(alignment: .center) {
                label()
                    .opacity(pendingTask != nil ? 0 : 1)
                if pendingTask != nil {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }
}
