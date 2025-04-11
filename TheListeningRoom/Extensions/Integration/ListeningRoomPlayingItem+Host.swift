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
import Foundation

extension ListeningRoomPlayingItem {
    init(_ song: Song) {
        self.init(id: song.id,
                  kind: .song,
                  startTime: song.startTime,
                  endTime: song.endTime,
                  assetURL: (try? song.currentURL()) ?? song.url,
                  artwork: song.frontCoverArtwork.map { ListeningRoomImage.artwork(id: $0.id) },
                  title: song.title,
                  artist: song.artist?.name,
                  albumTitle: song.album?.title,
                  albumArtist: song.albumArtist,
                  composer: song.composer,
                  genre: song.genre,
                  isCompilation: song.flags.contains(.compilation),
                  releaseDate: song.releaseDate,
                  trackNumber: song.trackNumber,
                  trackTotal: song.trackTotal,
                  discNumber: song.discNumber,
                  discTotal: song.discTotal,
                  lyrics: song.lyrics,
                  bpm: song.bpm)
    }
}
