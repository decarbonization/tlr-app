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

struct NowPlaying2: View {
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
    @Binding private var currentTime: TimeInterval
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack(alignment: .center) {
                Group {
                    //if let image = playingItem?.artwork.first?.image {
                    //    image.resizable()
                    //} else {
                        Color.gray
                    //}
                }
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 3.0))
                VStack(alignment: .leading) {
                    Text(verbatim: playingItem?.title ?? "--")
                        .lineLimit(2)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(verbatim: playingItem?.artist ?? "--")
                        .lineLimit(2)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            HStack {
                Slider(value: $currentTime, in: 0 ... totalTime)
                    .controlSize(.mini)
                    .tint(.orange)
                Text(Duration.seconds(currentTime), format: Duration.TimeFormatStyle(pattern: .minuteSecond))
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .padding(.all.subtracting([.top]), 8)
        }
    }
}

#Preview {
    @Previewable var playingItem = ListeningRoomPlayingItem(LibraryPreviewSupport.song)
    @Previewable @State var currentTime = TimeInterval(30.0)
    
    _NowPlayingContent(playingItem: playingItem,
                       totalTime: playingItem.duration,
                       currentTime: $currentTime)
}
