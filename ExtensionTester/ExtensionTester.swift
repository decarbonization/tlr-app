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
import ExtensionFoundation
import ExtensionKit
import SwiftUI

@main struct ExtensionTester: ListeningRoomExtension {
    var features: some ListeningRoomFeature {
        ListeningRoomSidebarSection(title: "Extension Tester") {
            ListeningRoomFeatureLink(sceneID: "player",
                                              title: "Player",
                                              systemImage: "music.note.list")
        }
        ListeningRoomFeatureSettings {
            ListeningRoomFeatureLink(sceneID: "general-settings",
                                              title: "General",
                                              systemImage: "gear")
            ListeningRoomFeatureLink(sceneID: "advanced-settings",
                                              title: "Advanced",
                                              systemImage: "gearshape.2")
        }
    }
    
    var body: some AppExtensionScene {
        ListeningRoomExtensionScene(id: "player") {
            PlayerTesterView()
        }
        ListeningRoomExtensionScene(id: "general-settings") {
            Label("General", systemImage: "gear")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
        }
        ListeningRoomExtensionScene(id: "advanced-settings") {
            Label("Advanced", systemImage: "gearshape.2")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
        }
    }
}
