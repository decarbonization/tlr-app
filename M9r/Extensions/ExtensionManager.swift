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

import ExtensionFoundation
import ExtensionKit
import os

@MainActor @Observable public final class ExtensionManager {
    public static let shared = ExtensionManager()
    
    static nonisolated let logger = Logger()
    
    private init() {
        processes = []
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
    
    private var processes: [ExtensionProcess]
    private(set) var sidebarSections: [ExtensionSidebarSection]
    
    private func refresh(_ newIdentities: Set<AppExtensionIdentity>) async {
        let oldIdentities = Set(processes.lazy.map { $0.identity })
        let removedIdentities = oldIdentities.subtracting(newIdentities)
        let toRemove = processes.indices(where: { removedIdentities.contains($0.identity) })
        let newIdentities = newIdentities.subtracting(oldIdentities)
        var toAdd = [ExtensionProcess]()
        for newIdentity in newIdentities {
            do {
                let newExtension = try await ExtensionProcess(launching: newIdentity)
                toAdd.append(newExtension)
            } catch {
                Self.logger.error("*** Could not launch app extension \(newIdentity.bundleIdentifier), reason: \(error)")
            }
        }
        processes.removeSubranges(toRemove)
        processes.append(contentsOf: toAdd)
        
        var newSidebarSections = [ExtensionSidebarSection]()
        for process in processes {
            do {
                let features = try await process.features
                for case .sidebarSection(let localizedTitle, let items) in features {
                    newSidebarSections.append(ExtensionSidebarSection(process: process, localizedTitle: localizedTitle, items: items))
                }
            } catch {
                Self.logger.error("*** Could not get features for \(process.identity.bundleIdentifier), reason: \(error)")
            }
        }
        newSidebarSections.sort(by: { $0.localizedTitle < $1.localizedTitle })
        self.sidebarSections = newSidebarSections
    }
}
