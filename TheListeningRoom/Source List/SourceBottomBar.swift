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

struct SourceBottomBar: View {
    @State private var isShowingTasks = false
    @State private var isShwoingErrors = false
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack {
            Button {
                modelContext.insert(Playlist(name: "Untitled Playlist"))
            } label: {
                Label("New Playlist", systemImage: "plus")
            }
            
            Spacer()
            
            @Bindable var tasks = Tasks.all
            if !tasks.inProgress.isEmpty {
                Button {
                    isShowingTasks = true
                } label: {
                    Label("Tasks", systemImage: "progress.indicator")
                }
                .popover(isPresented: $isShowingTasks) {
                    TaskList()
                }
            }
            
            @Bindable var errors = TaskErrors.all
            if !errors.presented.isEmpty {
                Button {
                    isShwoingErrors = true
                } label: {
                    Label("Errors", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.yellow)
                }
                .popover(isPresented: $isShwoingErrors) {
                    ErrorList()
                }
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .padding()
    }
}
