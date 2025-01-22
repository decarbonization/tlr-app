//
//  PlaybackControls.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/22/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import SwiftUI
import SFBAudioEngine

struct PlaybackControls: View {
    @Environment(PlaybackController.self) var playbackController
    
    var body: some View {
        HStack {
            Button {
                switch playbackController.playbackState {
                case .stopped:
                    break
                case .paused:
                    playbackController.resume()
                case .playing:
                    playbackController.pause()
                @unknown default:
                    fatalError()
                }
            } label: {
                switch playbackController.playbackState {
                case .stopped:
                    Label("Play", systemImage: "play.fill")
                case .paused:
                    Label("Resume", systemImage: "play.fill")
                case .playing:
                    Label("Pause", systemImage: "pause.fill")
                @unknown default:
                    EmptyView()
                }
            }
            .labelStyle(.iconOnly)
        }
    }
}
