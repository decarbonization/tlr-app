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

func findAudioFiles(at url: URL) -> [URL] {
    guard url.isFileURL else {
        return []
    }
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory) else {
        return []
    }
    guard isDirectory.boolValue else {
        return []
    }
    guard let enumerator = FileManager.default.enumerator(at: url,
                                                          includingPropertiesForKeys: nil,
                                                          options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
        return []
    }
    return [URL](
        enumerator.lazy
            .compactMap { $0 as? URL }
            .filter { AudioDecoder.handlesPaths(withExtension: $0.pathExtension) }
    )
}
