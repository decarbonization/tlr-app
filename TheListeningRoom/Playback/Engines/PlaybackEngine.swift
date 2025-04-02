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

import Foundation

enum PlaybackState: String, Codable {
    case playing
    case paused
    case stopped
}

enum PlaybackEvent {
    case playbackStateDidChange
    case playingItemDidChange
    case encounteredError(any Error)
    case endOfAudio
}

enum PlaybackError: Error {
    case couldNotSeek(to: TimeInterval)
}

protocol PlaybackEngine: Sendable {
    associatedtype Events: AsyncSequence<PlaybackEvent, Never>
    
    var events: Events { get }
    
    var playbackState: PlaybackState { get }
    var totalTime: TimeInterval? { get }
    var currentTime: TimeInterval? { get }
    var volume: Float { get }
    
    func setVolume(_ newVolume: Float) async throws -> Void
    func enqueue(_ itemURL: URL, startingAt startTime: TimeInterval, playNow: Bool) async throws -> Void
    func seek(toTime newTime: TimeInterval) async throws -> Void
    func pause() async throws -> Void
    func resume() async throws -> Void
    func stop() async throws -> Void
}
