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

extension Plugin {
    struct Source: Identifiable {
        init(from bundleURL: URL) throws {
            guard bundleURL.isFileURL else {
                throw PluginError.invalidBundleURL(bundleURL)
            }
            let manifestURL = bundleURL.appending(component: "manifest.json",
                                                  directoryHint: .notDirectory)
            let manifestData = try Data(contentsOf: manifestURL,
                                        options: [.mappedIfSafe])
            self.init(bundleURL: bundleURL.absoluteURL,
                      manifest: try Manifest.jsonDecoder.decode(Manifest.self, from: manifestData))
        }
        
        init(bundleURL: URL,
             manifest: Manifest) {
            self.bundleURL = bundleURL
            self.manifest = manifest
        }
        
        var id: String {
            manifest.name
        }
        let bundleURL: URL
        let manifest: Manifest
    }
}
