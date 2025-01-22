//
//  LibrarySong.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/22/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import Foundation
import SFBAudioEngine

struct LibrarySong: Identifiable {
    static func importing(contentsOf fileURL: URL) throws -> Self {
        let audioFile = try AudioFile(url: fileURL)
        return Self(id: .unique,
                    file: audioFile.url,
                    title: audioFile.metadata.title ?? fileURL.lastPathComponent,
                    artist: audioFile.metadata.artist,
                    album: audioFile.metadata.albumTitle)
    }
    
    let id: LibraryID
    let file: URL
    var title: String?
    var artist: String?
    var album: String?
}
