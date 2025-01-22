//
//  SongList.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/22/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import SwiftUI

struct SongList: View {
    @Environment(PlaybackController.self) var playbackController
    @Binding var library: Library
    @State private var selectedSongs = Set<LibraryID>()
    
    var body: some View {
        Table(library.allSongs, selection: $selectedSongs) {
            TableColumn("Title") { song in
                Text(verbatim: song.title ?? "")
            }
            TableColumn("Album") { song in
                Text(verbatim: song.album ?? "")
            }
            TableColumn("Artist") { song in
                Text(verbatim: song.artist ?? "")
            }
        }
        .contextMenu(forSelectionType: LibraryID.self) { selection in
            Button("Remove") {
                Task {
                    try await library.deleteSongs(selection)
                }
            }
        } primaryAction: { selection in
            guard let songID = selection.first else {
                return
            }
            guard let toPlay = library.allSongs.first(where: { $0.id == songID }) else {
                return
            }
            try! playbackController.play(toPlay)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                let progress = provider.loadTransferable(type: URL.self) { result in
                    let url = try! result.get()
                    Task {
                        try await library.importSongs([url])
                    }
                }
                if progress.isCancelled {
                    return false
                }
            }
            return true
        }
    }
}
