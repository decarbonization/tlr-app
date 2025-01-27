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

struct ImportItems: WorkItem {
    let library: LibraryActor
    let itemProviders: [NSItemProvider]
    
    func makeConfiguredProgress() -> Progress {
        let progress = Progress(totalUnitCount: 3)
        progress.localizedDescription = NSLocalizedString("Importing…", comment: "")
        return progress
    }
    
    func perform(reportingTo progress: Progress) async throws -> [Song] {
        let collectItemURLs = CollectItemURLs(itemProviders: itemProviders)
        let phase0 = collectItemURLs.makeConfiguredProgress()
        progress.addChild(phase0, withPendingUnitCount: 1)
        let itemURLs = try await collectItemURLs.perform(reportingTo: phase0)
        
        let findAudioFiles = FindAudioFiles(urls: itemURLs)
        let phase1 = findAudioFiles.makeConfiguredProgress()
        progress.addChild(phase1, withPendingUnitCount: 1)
        let fileURLs = try await findAudioFiles.perform(reportingTo: phase1)
        
        let importAudioFiles = ImportAudioFiles(library: library, toImport: fileURLs)
        let phase2 = importAudioFiles.makeConfiguredProgress()
        progress.addChild(phase2, withPendingUnitCount: 1)
        return try await importAudioFiles.perform(reportingTo: phase2)
    }
}
