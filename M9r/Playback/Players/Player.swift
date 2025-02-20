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

import Foundation

enum PlayerPlaybackState: Int, Codable {
    case playing
    case paused
    case stopped
}

enum PlayerEvent {
    case playbackStateChanged(PlayerPlaybackState)
    case nowPlayingChanged
    case encounteredError(any Error)
    case endOfAudio
}

protocol Player: Observable, Sendable {
    associatedtype Events: AsyncSequence<PlayerEvent, Never>
    
    var events: Events { get }
    
    @ObservationTracked var playbackState: PlayerPlaybackState { get }
    @ObservationTracked var totalTime: TimeInterval { get }
    @ObservationTracked var currentTime: TimeInterval { get set }
    @ObservationTracked var volume: Float { get }
    
    func enqueue(_ url: URL) async throws -> Void
    func play() async throws -> Void
    func pause() async throws -> Void
    func resume() async throws -> Void
    func stop() async throws -> Void
    func clearQueue() async throws -> Void
}
