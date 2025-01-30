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
    
    let tasks: Tasks
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
            tasks.remove(loadItemsProgress)
            
            let discoveringProgress = Progress(totalUnitCount: Int64(itemResults.count))
            discoveringProgress.localizedDescription = NSLocalizedString("Discovering…", comment: "")
            tasks.add(discoveringProgress)
            var fileResults = [Result<URL, any Error>]()
            for itemResult in itemResults {
                defer {
                    discoveringProgress.completedUnitCount += 1
                }
                switch itemResult {
                case .success(let url):
                    discoveringProgress.localizedAdditionalDescription = url.lastPathComponent
                    fileResults.append(contentsOf: findAudioFiles(at: url))
                case .failure(let error):
                    discoveringProgress.localizedAdditionalDescription = error.localizedDescription
                    fileResults.append(.failure(error))
                }
                
            }
            tasks.remove(discoveringProgress)
            
            Task(priority: .userInitiated) {
                let progress = Progress(totalUnitCount: Int64(fileResults.count))
                progress.localizedDescription = NSLocalizedString("Importing Songs…", comment: "")
                tasks.add(progress)
                defer {
                    tasks.remove(progress)
                }
                var addResults = [Result<Song, any Error>]()
                for fileResult in fileResults {
                    defer {
                        progress.completedUnitCount += 1
                    }
                    switch fileResult {
                    case .success(let fileURL):
                        progress.localizedAdditionalDescription = fileURL.lastPathComponent
                        do {
                            try await library.addSong(fileURL)
                        } catch {
                            Library.log.error("Could not import \(fileURL), reason: \(error)")
                        }
                    case .failure(let error):
                        progress.localizedAdditionalDescription = error.localizedDescription
                        addResults.append(.failure(error))
                    }
                }
                
                do {
                    try await library.garbageCollect()
                    try await library.save()
                } catch {
                    Library.log.error("Could not save library, reason: \(error)")
                }
            }
        }
        tasks.add(loadItemsProgress)
        
        return true
    }
}
