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

extension WebExtension {
    static let installed = List(searchURLs: List.defaultSearchURLs)
    
    @Observable final class List: Sendable {
        static var defaultSearchURLs: [URL] {
            var searchURLs = [URL]()
            if let builtInURL = Bundle.main.builtInPlugInsURL {
                searchURLs.append(builtInURL)
            }
            if let bundleID = Bundle.main.bundleIdentifier {
                let applicationSupportURL = URL.applicationSupportDirectory
                    .appending(component: bundleID, directoryHint: .isDirectory)
                let libraryURL = applicationSupportURL.appending(component: "Plugins",
                                                                 directoryHint: .isDirectory)
                searchURLs.append(libraryURL)
            }
            return searchURLs
        }
        
        init(searchURLs: [URL]) {
            self.searchURLs = searchURLs
            self._all = .init(initialState: [])
            Task {
                try await self.reload()
            }
        }
        
        private let searchURLs: [URL]
        private let _all: OSAllocatedUnfairLock<[WebExtension]>
        
        var all: [WebExtension] {
            access(keyPath: \.all)
            return _all.withLock { $0 }
        }
        
        var enabled: [WebExtension] {
            all.filter { $0.isEnabled }
        }
        
        private func reload() async throws {
            var sources = [WebExtension.ID: WebExtension.Source]()
            for searchURL in searchURLs {
                guard FileManager.default.fileExists(atPath: searchURL.path(percentEncoded: false)) else {
                    continue
                }
                let contents = try FileManager.default.contentsOfDirectory(at: searchURL,
                                                                           includingPropertiesForKeys: nil,
                                                                           options: [.skipsHiddenFiles])
                for bundleURL in contents where bundleURL.pathExtension == "mpext" {
                    let newSource = try WebExtension.Source(from: bundleURL)
                    sources[newSource.id] = newSource
                }
            }
            var updatedAll = all
            updatedAll.removeAll(where: { sources[$0.id] == nil })
            var toRemove = IndexSet()
            for (index, webExtension) in zip(updatedAll.indices, updatedAll) {
                guard let newSource = sources.removeValue(forKey: webExtension.id) else {
                    toRemove.insert(index)
                    continue
                }
                webExtension.updateSource(newSource)
            }
            updatedAll.remove(atOffsets: toRemove)
            
            for (_, newSource) in sources {
                updatedAll.append(WebExtension(source: newSource))
            }
            withMutation(keyPath: \.all) {
                _all.withLock { [/* copy */ updatedAll] all in
                    all = updatedAll
                }
            }
        }
        
        func add(byCopying bundleURL: URL) throws {
            guard let bundleID = Bundle.main.bundleIdentifier else {
                fatalError()
            }
            let applicationSupportURL = URL.applicationSupportDirectory
                .appending(component: bundleID, directoryHint: .isDirectory)
            let libraryURL = applicationSupportURL.appending(component: "Plugins",
                                                             directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: libraryURL, withIntermediateDirectories: true)
            let libraryBundleURL = libraryURL.appending(component: bundleURL.lastPathComponent,
                                                        directoryHint: .isDirectory)
            if FileManager.default.fileExists(atPath: libraryBundleURL.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: libraryBundleURL)
            }
            try FileManager.default.copyItem(at: bundleURL, to: libraryBundleURL)
            
            Task {
                try await self.reload()
            }
        }
        
        func remove(_ id: WebExtension.ID) throws {
            guard let toRemove = all.first(where: { $0.id == id }) else {
                fatalError()
            }
            
            try FileManager.default.removeItem(at: toRemove.bundleURL)
            
            Task {
                try await self.reload()
            }
        }
    }
}
