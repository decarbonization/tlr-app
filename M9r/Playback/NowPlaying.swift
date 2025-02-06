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

import SwiftUI

struct NowPlaying: View {
    init(playingItem: Song?,
         totalTime: TimeInterval,
         currentTime: Binding<TimeInterval>) {
        self.playingItem = playingItem
        self.totalTime = totalTime
        self._currentTime = currentTime
    }
    
    private let playingItem: Song?
    private let totalTime: TimeInterval
    @Binding private var currentTime: TimeInterval
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack(alignment: .center) {
                Group {
                    if let image = playingItem?.artwork.first?.image {
                        image.resizable()
                    } else {
                        Color.gray
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 3.0))
                VStack(alignment: .leading) {
                    Text(verbatim: playingItem?.title ?? "--")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(verbatim: playingItem?.artist?.name ?? "--")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            Slider(value: $currentTime, in: 0 ... totalTime)
                .padding(.all.subtracting([.top]), 8)
        }
    }
}

#Preview {
    @Previewable var song: Song = {
        let song = Song(url: URL(string: "about:blank")!,
                        startTime: 0,
                        endTime: 300)
        song.artwork = [
            Artwork(payloadHash: "",
                    payloadType: .data,
                    payload: NSImage(size: NSSize(width: 300, height: 300), flipped: true) { drawingRect in
                        let gradient = NSGradient(colors: [.systemCyan, .systemBlue])
                        gradient?.draw(in: drawingRect, angle: 45)
                        return true
                    }.tiffRepresentation!),
        ]
        song.title = "Halfway Highway"
        song.artist = Artist(name: "Blue States")
        song.album = Album(title: "Man Mountain")
        return song
    }()
    @Previewable @State var currentTime: TimeInterval = 30.0
    
    NowPlaying(playingItem: song,
               totalTime: song.endTime - song.startTime,
               currentTime: $currentTime)
}
