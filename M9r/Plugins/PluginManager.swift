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

import Foundation
import os

@Observable final class PluginManager: Sendable {
    static var defaultSearchURLs: [URL] {
        var searchURLs = [URL]()
        if let builtInPlugInsURL = Bundle.main.builtInPlugInsURL {
            searchURLs.append(builtInPlugInsURL)
        }
        if let bundleID = Bundle.main.bundleIdentifier {
            let applicationSupportURL = URL.applicationSupportDirectory
                .appending(component: bundleID, directoryHint: .isDirectory)
            let libraryPluginsURL = applicationSupportURL.appending(component: "Plugins",
                                                                    directoryHint: .isDirectory)
            searchURLs.append(libraryPluginsURL)
        }
        return searchURLs
    }
    
    static let shared = PluginManager(searchURLs: PluginManager.defaultSearchURLs)
    
    private init(searchURLs: [URL]) {
        self.searchURLs = searchURLs
        self._allPlugins = .init(initialState: [])
        refresh()
    }
    
    private let searchURLs: [URL]
    private let _allPlugins: OSAllocatedUnfairLock<[Plugin]>
    
    var allPlugins: [Plugin] {
        access(keyPath: \.allPlugins)
        return _allPlugins.withLock { $0 }
    }
    
    var enabledPlugins: [Plugin] {
        access(keyPath: \.enabledPlugins)
        return []
    }
    
    var disabledPlugins: [Plugin] {
        access(keyPath: \.disabledPlugins)
        return []
    }
    
    private func refresh() {
    }
    
    func installPlugin(at bundleURL: URL) async throws {
        throw CocoaError(.featureUnsupported)
    }
    
    func uninstallPlugin(_ plugin: Plugin) async throws {
        throw CocoaError(.featureUnsupported)
    }
    
    func enablePlugin(_ plugin: Plugin) throws {
        throw CocoaError(.featureUnsupported)
    }
    
    func disablePlugin(_ plugin: Plugin) throws {
        throw CocoaError(.featureUnsupported)
    }
}

extension PluginManager {
    convenience init(_forTesting_searchURLs searchURLs: [URL]) {
        self.init(searchURLs: searchURLs)
    }
}
