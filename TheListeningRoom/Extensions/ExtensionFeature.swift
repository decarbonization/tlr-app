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

import Foundation
import TheListeningRoomExtensionSDK

@dynamicMemberLookup struct ExtensionFeature<Feature: ListeningRoomExtensionFeature>: Identifiable {
    init(id: String,
         process: ListeningRoomExtensionProcess,
         feature: Feature) {
        self.id = id
        self.process = process
        self.feature = feature
    }
    
    init(process: ListeningRoomExtensionProcess,
         feature: ListeningRoomSidebarSection) where Feature == ListeningRoomSidebarSection {
        self.init(id: "\(process.id)-\(feature._title)-\(feature._items)",
                  process: process,
                  feature: feature)
    }
    
    init(process: ListeningRoomExtensionProcess,
         feature: ListeningRoomFeatureSettings) where Feature == ListeningRoomFeatureSettings {
        self.init(id: "\(process.id)-settings",
                  process: process,
                  feature: feature)
    }
    
    let id: String
    let process: ListeningRoomExtensionProcess
    let feature: Feature
    
    subscript<R>(dynamicMember property: KeyPath<Feature, R>) -> R {
        feature[keyPath: property]
    }
}
