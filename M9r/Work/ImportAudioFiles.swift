//
//  ImportAudioFiles.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/27/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import Foundation

func importAudioFiles(_ toImport: [URL],
                      into library: LibraryActor) async throws -> [Song] {
    try await PendingTasks.current.start(totalUnitCount: toImport.count,
                                         localizedDescription: NSLocalizedString("Importing Songs…", comment: "")) { progress in
        var songs = [Song]()
        for fileURL in toImport {
            songs.append(try await library.addSong(fileURL))
            progress.completedUnitCount += 1
        }
        try await library.save()
        return songs
    }
}
