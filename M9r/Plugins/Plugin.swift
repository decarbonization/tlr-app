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

final class Plugin: Identifiable, Sendable {
    static let didReloadNotification = Notification.Name("M9r.Plugin.didReloadNotification")
    
    private struct LoadedState {
        init(from bundleURL: URL) throws {
            guard bundleURL.isFileURL else {
                throw URLError(.badURL, userInfo: [
                    NSLocalizedDescriptionKey: "Plugins can only be loaded from a local file",
                    NSURLErrorKey: bundleURL,
                ])
            }
            let manifestURL = bundleURL.appending(component: "manifest.json",
                                                  directoryHint: .notDirectory)
            let manifestData = try Data(contentsOf: manifestURL,
                                        options: [.mappedIfSafe])
            self.bundleURL = bundleURL.absoluteURL
            self.manifest = try Manifest.jsonDecoder.decode(Manifest.self, from: manifestData)
        }
        
        let bundleURL: URL
        let manifest: Manifest
    }
    
    init(from bundleURL: URL) throws {
        _loadedState = .init(initialState: try LoadedState(from: bundleURL))
    }
    
    private let _loadedState: OSAllocatedUnfairLock<LoadedState>
    
    var bundleURL: URL {
        _loadedState.withLock { loadedState in
            loadedState.bundleURL
        }
    }
    
    var manifest: Manifest {
        _loadedState.withLock { loadedState in
            loadedState.manifest
        }
    }
    
    var id: String {
        manifest.name
    }
    
    func reload(from newBundleURL: URL? = nil) throws {
        let newLoadedState = try LoadedState(from: newBundleURL ?? bundleURL)
        try _loadedState.withLock { loadedState in
            if newLoadedState.manifest.name != loadedState.manifest.name {
                throw PluginError.nameMismatch(oldName: loadedState.manifest.name,
                                               newName: newLoadedState.manifest.name)
            }
            loadedState = newLoadedState
        }
        NotificationCenter.default.post(name: Self.didReloadNotification, object: self)
    }
    
    /// Returns the local file URL to load a resource with a given relative path.
    ///
    /// - important: This method does not check for the existence of the file.
    /// - parameter resource: A relative path to a resource in the plugin's bundle.
    /// - returns: A file URL which can be used by the plugin infrastructure.
    /// - throws: A `URLError` if the relative path resolves to a location outside
    /// of the plugin bundle.
    func resourceURL(_ resource: String) throws -> URL {
        guard var resourceURL = URL(string: resource, relativeTo: bundleURL) else {
            throw URLError(.badURL, userInfo: [
                NSLocalizedDescriptionKey: "Resource <\(resource)> is invalid",
            ])
        }
        resourceURL.resolveSymlinksInPath() // Block symlink escapes
        resourceURL.standardize() // Block relative path escapes
        guard resourceURL.path(percentEncoded: false).hasPrefix(bundleURL.path(percentEncoded: false)) else {
            throw URLError(.noPermissionsToReadFile, userInfo: [
                NSLocalizedDescriptionKey: "Resource <\(resource)> is outside of plugin bundle",
                NSURLErrorKey: resourceURL,
            ])
        }
        return resourceURL
    }
}
