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

extension Plugin {
    @Observable final class List: Sendable {
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
        
        static let installed = List(searchURLs: List.defaultSearchURLs)
        
        init(searchURLs: [URL]) {
            self.searchURLs = searchURLs
            self._all = .init(initialState: [])
            Task.detached(priority: .utility) { [weak self] in
                try await self?.reload()
                try Task.checkCancellation()
                let changes = AsyncStream { continuation in
                    do {
                        let stream = try FSEventStream(placesToWatch: searchURLs, sinceWhen: .current, latency: 1.0, flags: [.ignoreSelf]) { events in
                            continuation.yield(events)
                        }
                        if !stream.start() {
                            continuation.finish()
                        }
                        continuation.onTermination = { _ in
                            stream.stop()
                        }
                    } catch {
                        continuation.finish()
                    }
                }
                for await _ in changes {
                    try Task.checkCancellation()
                    try await self?.reload()
                    try Task.checkCancellation()
                }
            }
        }
        
        private let searchURLs: [URL]
        private let _all: OSAllocatedUnfairLock<[Plugin]>
        
        var all: [Plugin] {
            access(keyPath: \.all)
            return _all.withLock { $0 }
        }
        
        private func reload() async throws {
            var results = [Result<URL, any Error>]()
            var sources = [Plugin.ID: Plugin.Source]()
            for searchURL in searchURLs {
                guard FileManager.default.fileExists(atPath: searchURL.path(percentEncoded: false)) else {
                    continue
                }
                let contents = try FileManager.default.contentsOfDirectory(at: searchURL,
                                                                           includingPropertiesForKeys: nil,
                                                                           options: [.skipsHiddenFiles])
                for bundleURL in contents where bundleURL.pathExtension == "p4n" {
                    do {
                        let newSource = try Plugin.Source(from: bundleURL)
                        sources[newSource.id] = newSource
                    } catch {
                        results.append(.failure(error))
                    }
                }
            }
            var updatedAll = all
            updatedAll.removeAll(where: { sources[$0.id] == nil })
            var toRemove = IndexSet()
            for (index, plugin) in zip(updatedAll.indices, updatedAll) {
                guard let newSource = sources.removeValue(forKey: plugin.id) else {
                    toRemove.insert(index)
                    continue
                }
                plugin.updateSource(newSource)
            }
            updatedAll.remove(atOffsets: toRemove)
            
            for (_, newSource) in sources {
                updatedAll.append(Plugin(source: newSource))
            }
            withMutation(keyPath: \.all) {
                _all.withLock { [/* copy */ updatedAll] plugins in
                    plugins = updatedAll
                }
            }
        }
        
        func add(byCopying pluginURL: URL) throws {
            guard let bundleID = Bundle.main.bundleIdentifier else {
                fatalError()
            }
            let applicationSupportURL = URL.applicationSupportDirectory
                .appending(component: bundleID, directoryHint: .isDirectory)
            let libraryPluginsURL = applicationSupportURL.appending(component: "Plugins",
                                                                    directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: libraryPluginsURL, withIntermediateDirectories: true)
            let libraryPluginURL = libraryPluginsURL.appending(component: pluginURL.lastPathComponent,
                                                               directoryHint: .isDirectory)
            if FileManager.default.fileExists(atPath: libraryPluginURL.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: libraryPluginURL)
            }
            try FileManager.default.copyItem(at: pluginURL, to: libraryPluginURL)
        }
    }
}
