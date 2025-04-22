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

import ExtensionFoundation
import ExtensionKit
import TheListeningRoomExtensionSDK
import os

@MainActor @Observable public final class ExtensionManager {
    public static let shared = ExtensionManager()
    
    static nonisolated let logger = Logger()
    
    private init() {
        processes = []
        settings = []
        sidebarSections = []
        Task.detached(priority: .background) { [weak self] in
            do {
                let matches = try AppExtensionIdentity.matching(appExtensionPointIDs: "io.github.decarbonization.TheListeningRoom.uiextension")
                for await identities in matches {
                    guard !Task.isCancelled, let self else {
                        break
                    }
                    await refresh(Set(identities))
                }
            } catch {
                Self.logger.error("*** Could not match any app extensions, reason: \(error)")
            }
        }
    }
    
    private var processes: [ListeningRoomExtensionProcess]
    private(set) var settings: [ExtensionFeature<ListeningRoomFeatureSettings>]
    private(set) var sidebarSections: [ExtensionFeature<ListeningRoomSidebarSection>]
    
    private func refresh(_ newIdentities: Set<AppExtensionIdentity>) async {
        let existingIDs = Set(processes.lazy.map { $0.id })
        var visitedIDs = Set<String>()
        var toAdd = [ListeningRoomExtensionProcess]()
        for newIdentity in newIdentities {
            visitedIDs.insert(newIdentity.bundleIdentifier)
            do {
                let newExtension = try await ListeningRoomExtensionProcess(launching: newIdentity,
                                                                           endpoints: [])
                toAdd.append(newExtension)
            } catch {
                Self.logger.error("*** Could not launch app extension \(newIdentity.bundleIdentifier), reason: \(error)")
            }
        }
        let toRemove = existingIDs.subtracting(visitedIDs)
        processes.removeAll { process in
            toRemove.contains(process.id)
        }
        processes.append(contentsOf: toAdd)
        
        var newSettings = [ExtensionFeature<ListeningRoomFeatureSettings>]()
        var newSidebarSections = [ExtensionFeature<ListeningRoomSidebarSection>]()
        for process in processes {
            do {
                let features = try await process.features
                for feature in features {
                    switch feature {
                    case .settings(let settings):
                        newSettings.append(ExtensionFeature(process: process, feature: settings))
                    case .sidebarSection(let sidebarSection):
                        newSidebarSections.append(ExtensionFeature(process: process, feature: sidebarSection))
                    }
                }
            } catch {
                Self.logger.error("*** Could not get features for \(process.id), reason: \(error)")
            }
        }
        newSidebarSections.sort(by: { $0._title < $1._title })
        self.settings = newSettings
        self.sidebarSections = newSidebarSections
    }
}
