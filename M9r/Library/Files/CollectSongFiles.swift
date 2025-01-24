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
import SFBAudioEngine

func collectSongFiles(at url: URL,
                      using fileManager: FileManager = .default) throws -> [URL] {
    guard url.isFileURL else {
        return []
    }
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) else {
        return []
    }
    guard isDirectory.boolValue else {
        return [url]
    }
    guard let enumerator = fileManager.enumerator(at: url,
                                                  includingPropertiesForKeys: nil,
                                                  options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
        return []
    }
    return enumerator.compactMap { next in
        guard let nextURL = next as? URL else {
            return nil
        }
        guard AudioDecoder.handlesPaths(withExtension: nextURL.pathExtension) else {
            return nil
        }
        return nextURL
    }
}
