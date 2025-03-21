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

@main struct AppleMusicExtension: ListeningRoomExtension {
    var features: [ListeningRoomExtensionFeature] {
        [
            .sidebarSection(localizedTitle: "Apple Music", items: [
                ListeningRoomExtensionFeatureLink(sceneID: "radio", localizedTitle: "Radio", image: .systemImage(name: "radio")),
                ListeningRoomExtensionFeatureLink(sceneID: "search", localizedTitle: "Search", image: .systemImage(name: "magnifyingglass")),
            ])
        ]
    }
    
    var body: some AppExtensionScene {
        ListeningRoomExtensionScene(id: "radio") {
            VStack {
                Label("Radio", systemImage: "radio")
                    .font(.largeTitle)
                    .foregroundStyle(.primary)
            }
        }
        ListeningRoomExtensionScene(id: "search") {
            VStack {
                Label("Search", systemImage: "magnifyingglass")
                    .font(.largeTitle)
                    .foregroundStyle(.primary)
            }
        }
    }
}
