/*
 * The Listening Room Project
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

import TheListeningRoomExtensionSDK
import SwiftUI
import SFBAudioEngine

struct PlaybackControls: View {
    @Environment(Player.self) private var player
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                Task {
                    do {
                        try await player.skipPrevious()
                    } catch {
                        AppNotificationCenter.global.present(ListeningRoomNotification(presenting: error))
                    }
                }
            } label: {
                Label("Previous Track", systemImage: "backward.end.alt.fill")
            }
            .disabled(player.playingItem == nil)
            .keyboardShortcut(.leftArrow, modifiers: .command)
            Spacer()
            Button {
                Task {
                    switch player.playbackState {
                    case .stopped:
                        do {
                            guard let firstItem = player.queue.itemIDs.first else {
                                return
                            }
                            try await player.playItem(withID: firstItem)
                        } catch {
                            AppNotificationCenter.global.present(ListeningRoomNotification(presenting: error))
                        }
                    case .paused:
                        try await player.resume()
                    case .playing:
                        try await player.pause()
                    @unknown default:
                        fatalError()
                    }
                }
            } label: {
                switch player.playbackState {
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
            .disabled(player.queue.itemIDs.isEmpty)
            .keyboardShortcut(.space)
            Spacer()
            Button {
                Task {
                    do {
                        try await player.skipNext()
                    } catch {
                        AppNotificationCenter.global.present(ListeningRoomNotification(presenting: error))
                    }
                }
            } label: {
                Label("Previous Track", systemImage: "forward.end.alt.fill")
            }
            .disabled(player.playingItem == nil)
            .keyboardShortcut(.rightArrow, modifiers: .command)
            Spacer()
        }
        .labelStyle(.iconOnly)
    }
}
