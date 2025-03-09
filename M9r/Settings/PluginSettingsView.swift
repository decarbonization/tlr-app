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

import SwiftUI

struct PluginSettingsView: View {
    @State private var selection: Plugin.ID?
    @State private var isShowingImporter = false
    @State private var isShowingConfirmUninstall = false
    
    var body: some View {
        @Bindable var pluginList = Plugin.List.installed
        VStack(alignment: .leading) {
            HStack {
                List(pluginList.all, selection: $selection) { plugin in
                    Text(verbatim: plugin.manifest.shortName ?? plugin.manifest.name)
                }
                .listStyle(.bordered)
                .frame(width: 200)
                
                VStack(alignment: .leading) {
                    Form {
                        if let selectedPlugin = pluginList.all.first(where: { $0.id == selection }) {
                            @Bindable var selectedPlugin = selectedPlugin
                            Toggle("Enabled", isOn: $selectedPlugin.isEnabled)
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .backgroundStyle(.regularMaterial)
                .border(.tertiary, width: 1.0)
            }
            
            HStack {
                Button("Install") {
                    isShowingImporter = true
                }
                .fileImporter(isPresented: $isShowingImporter, allowedContentTypes: [.bundle]) { result in
                    do {
                        let importURL = try result.get()
                        guard importURL.startAccessingSecurityScopedResource() else {
                            throw CocoaError(.fileReadNoPermission)
                        }
                        defer {
                            importURL.stopAccessingSecurityScopedResource()
                        }
                        try Plugin.List.installed.add(byCopying: importURL)
                    } catch {
                        TaskErrors.all.present(error)
                    }
                }
                Button("Uninstall") {
                    isShowingConfirmUninstall = true
                }
                .disabled(selection == nil)
                .alert("Are you sure you want to uninstall this plugin?", isPresented: $isShowingConfirmUninstall, presenting: selection) { selection in
                    Button("Cancel", role: .cancel) {
                        // Do nothing.
                    }
                    Button("Uninstall", role: .destructive) {
                        do {
                            try Plugin.List.installed.remove(selection)
                        } catch {
                            TaskErrors.all.present(error)
                        }
                    }
                }
            }
        }
    }
}
