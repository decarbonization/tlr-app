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

struct ErrorList: View {
    @State private var selectedErrors = Set<PresentableError.ID>()
    
    var body: some View {
        Table(TaskErrors.all.presented, selection: $selectedErrors) {
            TableColumn("Type") { error in
                Text(verbatim: "\(type(of: error.unwrap))")
            }
            TableColumn("Captured") { error in
                Text(error.capturedAt, format: .dateTime)
            }
            TableColumn("Description") { error in
                Text(verbatim: error.localizedDescription)
            }
        }
        .onDeleteCommand {
            TaskErrors.all.clearPresented(matching: selectedErrors)
        }
        .onCopyCommand {
            TaskErrors.all.presented
                .lazy
                .filter { selectedErrors.contains($0.id) }
                .map { NSItemProvider(object: "\(type(of: $0.unwrap))\t\($0.capturedAt)\t\($0.localizedDescription)" as NSString) }
        }
        .toolbar {
            Button {
                TaskErrors.all.clearPresented()
            } label: {
                Label("Clear Errors", systemImage: "trash")
            }
            .disabled(TaskErrors.all.presented.isEmpty)
        }
    }
}
