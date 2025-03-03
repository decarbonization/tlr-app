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
import Testing
@testable import M9r

@Suite struct PluginTests {
    private func stubPlugin(creatingManifest createManifest: Bool = true,
                            manifest: @autoclosure () -> Plugin.Manifest = Plugin.Manifest(manifestVersion: .v0,
                                                                                           name: "Stub",
                                                                                           version: "0.0.0")) throws -> URL {
        let bundleURL = URL.temporaryDirectory
            .appending(component: "\(UUID().uuidString).p4n", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: bundleURL,
                                                withIntermediateDirectories: true)
        
        if createManifest {
            let manifestData = try Plugin.Manifest.jsonEncoder.encode(manifest())
            let manifestURL = bundleURL.appending(component: "manifest.json", directoryHint: .notDirectory)
            try manifestData.write(to: manifestURL, options: .atomic)
        }
        return bundleURL
    }
    
    @Test func rejectsNonFileURLs() throws {
        #expect(throws: Error.self, performing: {
            try Plugin(from: try #require(URL(string: "http://localhost:8000")))
        })
    }
    
    @Test func requiresManifest() throws {
        let bundleURL = try stubPlugin(creatingManifest: false)
        #expect(throws: Error.self, performing: {
            try Plugin(from: bundleURL)
        })
    }
    
    @Test func canLoadPlugin() throws {
        let bundleURL = try stubPlugin()
        let plugin = try Plugin(from: bundleURL)
        #expect(plugin.manifest.name == "Stub")
    }
    
    @Test func blocksResourceAccessOutsideBundle() throws {
        let bundleURL = try stubPlugin()
        let plugin = try Plugin(from: bundleURL)
        #expect(throws: URLError.self, performing: {
            try plugin.resourceURL("../secrets.txt")
        })
        
        try FileManager.default.createSymbolicLink(at: bundleURL.appending(component: "tmp",
                                                                           directoryHint: .isDirectory),
                                                   withDestinationURL: URL.temporaryDirectory)
        try "secrets".write(to: URL.temporaryDirectory.appending(component: "secrets.txt",
                                                                 directoryHint: .notDirectory),
                            atomically: true,
                            encoding: .utf8)
        #expect(throws: URLError.self, performing: {
            try plugin.resourceURL("tmp/secrets.txt")
        })
    }
    
    @Test func reloadReplacesState() async throws {
        let bundleURL = try stubPlugin()
        let plugin = try Plugin(from: bundleURL)
        #expect(plugin.bundleURL == bundleURL)
        #expect(plugin.manifest.version == "0.0.0")
        
        let newBundleURL = try stubPlugin(manifest: Plugin.Manifest(manifestVersion: .v0,
                                                                    name: "Stub",
                                                                    version: "0.1.0"))
        try plugin.reload(from: newBundleURL)
        #expect(plugin.bundleURL == newBundleURL)
        #expect(plugin.manifest.version == "0.1.0")
    }
    
    @Test func reloadRequiresNameToNotChange() async throws {
        let bundleURL = try stubPlugin()
        let plugin = try Plugin(from: bundleURL)
        #expect(plugin.bundleURL == bundleURL)
        #expect(plugin.manifest.version == "0.0.0")
        
        let newBundleURL = try stubPlugin(manifest: Plugin.Manifest(manifestVersion: .v0,
                                                                    name: "Thump",
                                                                    version: "0.0.0"))
        #expect(throws: PluginError.self, performing: {
            try plugin.reload(from: newBundleURL)
        })
    }
    
    @Test func reloadPostsNotification() async throws {
        let bundleURL = try stubPlugin()
        let plugin = try Plugin(from: bundleURL)
        try await confirmation { didReload in
            let observer = NotificationCenter.default.addObserver(forName: Plugin.didReloadNotification, object: plugin, queue: nil) { _ in
                didReload()
            }
            try withExtendedLifetime(observer) {
                try plugin.reload()
            }
        }
    }
}
