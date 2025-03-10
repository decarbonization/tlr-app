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
import UniformTypeIdentifiers

extension UTType {
    static let musicPlayerWebExtension = UTType(exportedAs: "io.github.decarbonization.M9r.webExtension",
                                                conformingTo: .directory)
}

@Observable final class WebExtension: Identifiable, Sendable {
    init(source: Source) {
        _source = .init(initialState: source)
    }
    
    private let _source: OSAllocatedUnfairLock<Source>
    
    func updateSource(_ newSource: Source) {
        withMutation(keyPath: \.bundleURL) {
            withMutation(keyPath: \.manifest) {
                _source.withLock { source in
                    source = newSource
                }
            }
        }
    }
    
    var bundleURL: URL {
        access(keyPath: \.bundleURL)
        return _source.withLock { loadedState in
            loadedState.bundleURL
        }
    }
    
    var manifest: Manifest {
        access(keyPath: \.manifest)
        return _source.withLock { loadedState in
            loadedState.manifest
        }
    }
    
    var id: String {
        manifest.name
    }
    
    var persistentID: UUID {
        if let existingPersistentID = Configuration.persistent.ids[id] {
            return existingPersistentID
        } else {
            let newPersistentID = UUID()
            Configuration.persistent.ids[id] = newPersistentID
            return newPersistentID
        }
    }
    
    var isEnabled: Bool {
        get {
            access(keyPath: \.isEnabled)
            return !Configuration.persistent.disabled.contains(id)
        }
        set {
            withMutation(keyPath: \.isEnabled) {
                if newValue {
                    Configuration.persistent.disabled.remove(id)
                } else {
                    Configuration.persistent.disabled.insert(id)
                }
            }
        }
    }
    
    /// Returns the local file URL to load a resource with a given relative path.
    ///
    /// - important: This method does not check for the existence of the file.
    /// - parameter resource: A relative path to a resource in the extension's bundle.
    /// - returns: A file URL which can be used by the web extension infrastructure.
    /// - throws: A `URLError` if the relative path resolves to a location outside
    /// of the web extension bundle.
    func resourceURL(_ resource: String) throws -> URL {
        var resourceURL = bundleURL.appending(path: resource, directoryHint: .inferFromPath)
        resourceURL.resolveSymlinksInPath() // Block symlink escapes
        resourceURL.standardize() // Block relative path escapes
        guard resourceURL.path(percentEncoded: false).hasPrefix(bundleURL.path(percentEncoded: false)) else {
            throw WebExtensionError.invalidResource(resource)
        }
        return resourceURL
    }
}
