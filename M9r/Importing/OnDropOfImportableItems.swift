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

extension View {
    @ViewBuilder func onDropOfImportableItems() -> some View {
        modifier(ImportDropViewModifier())
    }
}

private struct ImportDropViewModifier: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    
    func body(content: Content) -> some View {
        content.onDrop(of: ImportDropDelegate.supportedContentTypes,
                       delegate: ImportDropDelegate(modelContext: modelContext))
    }
}

private struct ImportDropDelegate: DropDelegate {
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
        
        Task(priority: .userInitiated) {
            let itemResults = await loadAll(URL.self, from: itemProviders)
            Library.performChanges(inContainerOf: modelContext) { library in
                let fileResults = await findAudioFiles(fromContentsOf: itemResults)
                
                let progress = Progress(totalUnitCount: Int64(fileResults.count))
                progress.localizedDescription = NSLocalizedString("Importing Songs…", comment: "")
                Tasks.all.begin(progress)
                defer {
                    Tasks.all.end(progress)
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
                            addResults.append(.failure(error))
                        }
                    case .failure(let error):
                        progress.localizedAdditionalDescription = error.localizedDescription
                        addResults.append(.failure(error))
                    }
                }
                
                TaskErrors.all.present(addResults)
            } catching: { error in
                TaskErrors.all.present(error)
            }
        }
        
        return true
    }
}
