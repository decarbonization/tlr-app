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

import ExtensionKit
import TheListeningRoomExtensionSDK
import SwiftUI

struct ExtensionsSettingsView: View {
    var body: some View {
        @Bindable var extensionManager = ExtensionManager.shared
        NavigationSplitView {
            List {
                ForEach(extensionManager.settings) { settings in
                    NavigationLink {
                        ExtensionHostView(process: settings.process,
                                          sceneID: settings._sceneID)
                    } label: {
                        Label(settings.process.localizedName, systemImage: "puzzlepiece.extension")
                    }

                }
                Divider()
                NavigationLink {
                    _ManageExtensionsSettingsView()
                } label: {
                    Label("Manage Extensions", systemImage: "switch.2")
                }
            }
            .toolbar(removing: .sidebarToggle)
        } detail: {
            NavigationStack {
                NoContentView("No Selection")
            }
        }
    }
}

private struct _ManageExtensionsSettingsView: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> EXAppExtensionBrowserViewController {
        EXAppExtensionBrowserViewController()
    }
    
    func updateNSViewController(_ nsViewController: EXAppExtensionBrowserViewController, context: Context) {
    }
}
