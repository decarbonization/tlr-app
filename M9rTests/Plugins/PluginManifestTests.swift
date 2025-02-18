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

@Suite struct PluginManifestTests {
    @Test func disallowsUnknownManifestVersions() throws {
        let jsonData = try #require("""
        2
        """.data(using: .utf8))
        
        #expect(throws: Error.self, performing: {
            try Plugin.Manifest.jsonDecoder.decode(Plugin.ManifestVersion.self, from: jsonData)
        })
    }
    
    @Test func allowsDecodingUnknownPermissions() throws {
        let jsonData = try #require("""
        "podBayDoors"
        """.data(using: .utf8))
        
        let permission = try Plugin.Manifest.jsonDecoder.decode(Plugin.Permission.self, from: jsonData)
        #expect(permission == Plugin.Permission(rawValue: "podBayDoors"))
    }
    
    @Test func decodesWellformedManifest() throws {
        let jsonData = try #require("""
        {
            "manifestVersion": 0,
            "name": "A Test Plugin",
            "shortName": "Test",
            "description": "Not a real plugin",
            "developer": {
                "name": "Alistair McFaker",
                "url": "about:blank",
            },
            "homepage_url": "about:blank",
            "icons": {
                "48": "about:blank"
            },
            "permissions": [
                "readLibrary"
            ],
            "version": "0.0.0",
            "versionName": "0.0 (nightly)"
        }
        """.data(using: .utf8))
        
        let plugin = try Plugin.Manifest.jsonDecoder.decode(Plugin.Manifest.self, from: jsonData)
        #expect(plugin.manifestVersion == .v0)
        #expect(plugin.name == "A Test Plugin")
        #expect(plugin.shortName == "Test")
        #expect(plugin.description == "Not a real plugin")
        #expect(plugin.developer?.name == "Alistair McFaker")
        #expect(plugin.developer?.url == "about:blank")
        #expect(plugin.homepageUrl == "about:blank")
        #expect(plugin.icons == ["48": "about:blank"])
        #expect(plugin.permissions == [Plugin.Permission(rawValue: "readLibrary")])
        #expect(plugin.version == "0.0.0")
        #expect(plugin.versionName == "0.0 (nightly)")
    }
}
