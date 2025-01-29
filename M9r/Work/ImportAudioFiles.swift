//
//  ImportAudioFiles.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/27/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import Foundation

func importAudioFiles(_ toImport: [URL],
                      into library: Library) async throws -> [Song] {
    try await Progress.begin {
        let progress = Progress(totalUnitCount: Int64(toImport.count))
        progress.localizedDescription = NSLocalizedString("Importing Songs…", comment: "")
        return progress
    } task: { progress in
        Task(priority: .background) {
            var songs = [Song]()
            for fileURL in toImport {
                songs.append(try await library.addSong(fileURL))
                progress.completedUnitCount += 1
            }
            try await library.save()
            return songs
        }
    }.value
}
