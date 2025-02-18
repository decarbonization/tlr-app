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
    var body: some View {
        @Bindable var pluginManager = PluginManager.shared
        
        HStack {
            VStack(alignment: .leading) {
                List {
                    Section("Enabled") {
                        ForEach(pluginManager.enabledPlugins) { plugin in
                            Text(verbatim: plugin.manifest.shortName ?? plugin.manifest.name)
                        }
                    }
                    Section("Disabled") {
                        ForEach(pluginManager.disabledPlugins) { plugin in
                            Text(verbatim: plugin.manifest.shortName ?? plugin.manifest.name)
                        }
                    }
                }
                .listStyle(.bordered)
                Button("Add", systemImage: "plus") {
                    
                }
                .buttonStyle(.accessoryBar)
                .labelStyle(.iconOnly)
            }
            .frame(width: 200)
            VStack {
                
            }
            .frame(width: 300)
        }
        .padding()
    }
}
