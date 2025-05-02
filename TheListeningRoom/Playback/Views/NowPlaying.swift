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

struct NowPlaying: View {
    @Environment(Player.self) private var player
    
    var body: some View {
        @Bindable var player = player
        
        _NowPlayingContent(playingItem: player.playingItem,
                           totalTime: player.totalTime,
                           currentTime: $player.currentTime)
    }
}

private struct _NowPlayingContent: View {
    init(playingItem: ListeningRoomPlayingItem?,
         totalTime: TimeInterval,
         currentTime: Binding<TimeInterval>) {
        self.playingItem = playingItem
        self.totalTime = totalTime
        self._currentTime = currentTime
    }
    
    private let playingItem: ListeningRoomPlayingItem?
    private let totalTime: TimeInterval
    @State private var colors = [RGBColor]()
    @Binding private var currentTime: TimeInterval
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            Spacer()
            Group {
                if let image = playingItem?.artwork?.image(in: modelContext) {
                    image.resizable()
                } else {
                    Color.gray
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 3.0))
            VStack(spacing: 2) {
                Marquee {
                    Text(verbatim: playingItem?.title ?? "--")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                Marquee {
                    Text(verbatim: playingItem?.artist ?? "--")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            HStack {
                Slider(value: $currentTime, in: 0 ... totalTime)
                    .tint(colors.isEmpty ? .orange : colors[3].color)
                Text(Duration.seconds(currentTime), format: Duration.TimeFormatStyle(pattern: .minuteSecond))
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            PlaybackControls()
                .imageScale(.large)
                .buttonStyle(.borderless)
            Spacer()
        }
        .padding()
        .task(id: playingItem?.id) {
            colors = []
            guard let artwork = playingItem?.artwork,
            let artworkColors = await artwork.predominantColors(in: modelContext) else {
                return
            }
            colors = artworkColors
        }
        .background(colors.isEmpty ? .clear : colors[0].color)
        .foregroundStyle(colors.isEmpty ? Color.primary : colors[1].color,
                         colors.isEmpty ? Color.secondary : colors[2].color)
    }
}

#Preview {
    @Previewable var playingItem = ListeningRoomPlayingItem(LibraryPreviewSupport.song)
    @Previewable @State var currentTime = TimeInterval(30.0)
    
    _NowPlayingContent(playingItem: playingItem,
                       totalTime: playingItem.duration,
                       currentTime: $currentTime)
}
