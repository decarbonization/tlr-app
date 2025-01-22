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
import SwiftUI

protocol Library: AnyObject, Observable {
    /// All songs known to the library.
    var allSongs: [LibrarySong] { get }
    
    /// Import song files from the specified URLs.
    ///
    /// - parameter urls: A collection of file URLs referring to song files.
    /// - returns: A set containing the identifiers of the songs inserted into the library.
    /// - throws: An error indicating why the import operation failed.
    func importSongs(_ urls: some Sequence<URL>) async throws -> Set<LibraryID>
    
    /// Update a given collection of songs in the library.
    ///
    /// - parameter songs: A collection of songs whose properties have been changed.
    /// Those changes will be writen back to the library.
    /// - parameter updateFiles: Whether the files backing the songs on the file system
    /// should be updated too.
    /// - throws: An error if the library or a file could not be updated.
    func updateSongs(_ songs: inout some MutableCollection<LibrarySong>,
                     writingToFiles updateFiles: Bool) async throws
    
    /// Delete a given collection of songs from the library.
    ///
    /// - parameter songIDs: A collection of identifiers specifying the songs to delete.
    /// - returns: The identifiers of the songs that were removed.
    /// - throws: An error if the library could not be updated.
    func deleteSongs(_ songIDs: some Sequence<LibraryID>) async throws -> Set<LibraryID>
}

extension EnvironmentValues {
    @Entry var library: Library = TransientLibrary()
}
