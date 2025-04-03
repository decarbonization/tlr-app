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
import SwiftData
import SwiftUI

enum LibraryPreviewSupport {
    static var artwork: Artwork {
        Artwork(payloadHash: "",
                payloadType: .data,
                payload: NSImage(size: NSSize(width: 300, height: 300), flipped: true) { drawingRect in
                    let gradient = NSGradient(colors: [.systemCyan, .systemBlue])
                    gradient?.draw(in: drawingRect, angle: 45)
                    return true
                }.tiffRepresentation!)
    }
    
    static var song: Song {
        let song = Song(url: URL(string: "about:blank")!,
                        startTime: 0,
                        endTime: 300)
        song.artwork = [Self.artwork]
        song.title = "Halfway Highway"
        song.artist = Artist(name: "Blue States")
        song.album = Album(title: "Man Mountain", artist: song.artist)
        return song
    }
}
