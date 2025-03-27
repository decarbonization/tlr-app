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
        VStack(spacing: 0.0) {
            List(TaskErrors.all.presented, selection: $selectedErrors) { error in
                VStack(alignment: .leading) {
                    Text(verbatim: "\(error.domainAndCode)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(error.capturedAt, format: .dateTime)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(verbatim: error.localizedDescription)
                        .multilineTextAlignment(.leading)
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
            }
            .onDeleteCommand {
                TaskErrors.all.clearPresented(matching: selectedErrors)
            }
            .onCopyCommand {
                TaskErrors.all.presented
                    .lazy
                    .filter { selectedErrors.contains($0.id) }
                    .map { NSItemProvider(object: "\($0.domainAndCode)\t\($0.capturedAt)\t\($0.localizedDescription)" as NSString) }
            }
            .listStyle(.plain)
            .frame(minWidth: 250, minHeight: 250)
            
            Divider()
            
            HStack(alignment: .center) {
                Button {
                    TaskErrors.all.clearPresented()
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
                .disabled(TaskErrors.all.presented.isEmpty)
            }
            .controlSize(.small)
            .padding()
        }
    }
}
