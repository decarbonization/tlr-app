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

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct LibraryDropDelegate: DropDelegate {
    static let supportedContentTypes = [UTType.fileURL]
    
    let modelContext: ModelContext
    
    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: Self.supportedContentTypes)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        let itemProviders = info.itemProviders(for: Self.supportedContentTypes)
        guard !itemProviders.isEmpty else {
            return false
        }
        
        let library = Library(modelContainer: modelContext.container)
        let loadItemsProgress = loadAll(URL.self, from: itemProviders) { itemResults, loadItemsProgress in
            library.tasks.remove(loadItemsProgress)
            
            let discoveringProgress = Progress(totalUnitCount: Int64(itemResults.count))
            discoveringProgress.localizedDescription = NSLocalizedString("Discovering…", comment: "")
            library.tasks.add(discoveringProgress)
            var fileResults = [Result<URL, any Error>]()
            for itemResult in itemResults {
                defer {
                    discoveringProgress.completedUnitCount += 1
                }
                switch itemResult {
                case .success(let url):
                    discoveringProgress.localizedAdditionalDescription = url.lastPathComponent
                    for fileURL in findAudioFiles(at: url) {
                        fileResults.append(.success(fileURL))
                    }
                case .failure(let error):
                    fileResults.append(.failure(error))
                }
                
            }
            library.tasks.remove(discoveringProgress)
            
            Task(priority: .userInitiated) {
                await library.addSongs(fromContentsOf: fileResults)
                try await library.garbageCollect()
                try await library.save()
            }
        }
        library.tasks.add(loadItemsProgress)
        
        return true
    }
}
