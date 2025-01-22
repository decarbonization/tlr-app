//
//  Library.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/22/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import Foundation

@MainActor protocol Library: Observable {
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
    /// - parameter songs: A collection of songs to delete.
    /// - returns: The identifiers of the songs that were removed.
    /// - throws: An error if the library could not be updated.
    func deleteSongs(_ songs: some Sequence<LibrarySong>) async throws -> Set<LibraryID>
}
