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

@Suite struct WebExtensionTests {
    private func stubWebExtension(creatingManifest createManifest: Bool = true,
                                  manifest: @autoclosure () -> WebExtension.Manifest = WebExtension.Manifest(manifestVersion: .v0,
                                                                                                             name: "Stub",
                                                                                                             version: "0.0.0")) throws -> URL {
        let bundleURL = URL.temporaryDirectory
            .appending(component: "\(UUID().uuidString).mpext", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: bundleURL,
                                                withIntermediateDirectories: true)
        
        if createManifest {
            let manifestData = try WebExtension.Manifest.jsonEncoder.encode(manifest())
            let manifestURL = bundleURL.appending(component: "manifest.json", directoryHint: .notDirectory)
            try manifestData.write(to: manifestURL, options: .atomic)
        }
        return bundleURL
    }
    
    @Test func sourceRejectsNonFileURLs() throws {
        #expect(throws: Error.self, performing: {
            try WebExtension.Source(from: try #require(URL(string: "http://localhost:8000")))
        })
    }
    
    @Test func sourceRequiresManifest() throws {
        let bundleURL = try stubWebExtension(creatingManifest: false)
        #expect(throws: Error.self, performing: {
            try WebExtension.Source(from: bundleURL)
        })
    }
    
    @Test func canLoadWebExtension() throws {
        let bundleURL = try stubWebExtension()
        let stubSource = try WebExtension.Source(from: bundleURL)
        let subject = WebExtension(source: stubSource)
        #expect(subject.manifest.name == "Stub")
    }
    
    @Test func blocksResourceAccessOutsideBundle() throws {
        let bundleURL = try stubWebExtension()
        let stubSource = try WebExtension.Source(from: bundleURL)
        let subject = WebExtension(source: stubSource)
        #expect(throws: WebExtensionError.self, performing: {
            try subject.resourceURL("../secrets.txt")
        })
        
        try FileManager.default.createSymbolicLink(at: bundleURL.appending(component: "tmp",
                                                                           directoryHint: .isDirectory),
                                                   withDestinationURL: URL.temporaryDirectory)
        try "secrets".write(to: URL.temporaryDirectory.appending(component: "secrets.txt",
                                                                 directoryHint: .notDirectory),
                            atomically: true,
                            encoding: .utf8)
        #expect(throws: WebExtensionError.self, performing: {
            try subject.resourceURL("tmp/secrets.txt")
        })
    }
}
