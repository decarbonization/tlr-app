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

import TheListeningRoomExtensionSDK
import SwiftData
import SwiftUI

struct ExtensionBrowser: View {
    private struct Extension: Hashable {
        let process: ListeningRoomExtensionProcess
        let sceneID: String
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.process === rhs.process && lhs.sceneID == rhs.sceneID
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(process))
            hasher.combine(sceneID)
        }
    }
    
    @State private var selection: Extension?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HSplitView {
            List(selection: $selection) {
                @Bindable var extensionManager = ExtensionManager.shared
                ForEach(extensionManager.sidebarSections) { sidebarSection in
                    Section(sidebarSection._title) {
                        ForEach(sidebarSection._items, id: \._sceneID) { item in
                            Label {
                                Text(verbatim: item._title)
                            } icon: {
                                item._icon?.image(in: modelContext)
                            }
                            .tag(Extension(process: sidebarSection.process,
                                           sceneID: item._sceneID))
                            .allowsHitTesting(false)
                        }
                    }
                }
            }
            .frame(minWidth: 100, idealWidth: 150, maxWidth: 250)
            
            VStack(alignment: .leading, spacing: 0.0) {
                if let selection {
                    ExtensionHostView(process: selection.process,
                                      sceneID: selection.sceneID)
                } else {
                    NoContentView("No Selection")
                }
            }
        }
    }
}
