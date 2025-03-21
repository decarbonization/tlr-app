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

import ExtensionKit
import ListeningRoomExtensionSDK
import SwiftUI

struct ExtensionsSourceListSection: View {
    var body: some View {
        @Bindable var extensionManager = ExtensionManager.shared
        ForEach(extensionManager.sidebarSections) { sidebarSection in
            Section(sidebarSection.localizedTitle) {
                ForEach(sidebarSection.items, id: \.sceneID) { item in
                    NavigationLink {
                        ExtensionHostView(process: sidebarSection.process,
                                          sceneID: item.sceneID)
                    } label: {
                        switch item.image {
                        case .systemImage(let name):
                            Label(item.localizedTitle, systemImage: name)
                        case nil:
                            Text(verbatim: item.localizedTitle)
                        }
                    }
                }
            }
        }
    }
}
