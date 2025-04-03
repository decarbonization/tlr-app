/*
 * MIT No Attribution
 *
 * Copyright 2025 Peter "Kevin" Contreras
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

public enum ListeningRoomPlaybackEvent: Codable, Sendable {
    case playbackStateDidChange
    case playingItemChanged
    case encounteredError(domain: String, code: Int, userInfo: [String: AnyCodable] = [:])
    case endOfAudio(wantsQueueToAdvance: Bool)
    
    public static func encounteredError(_ error: any Error) -> Self {
        let nsError = error as NSError
        return .encounteredError(domain: nsError.domain,
                                 code: nsError.code,
                                 userInfo: nsError.userInfo.compactMapValues { ($0 as? any Codable).map { AnyCodable(wrapping: $0) } })
    }
}

public protocol ListeningRoomPlaybackEngine: Sendable {
    typealias Item = ListeningRoomPlayingItem
    typealias PlaybackEvent = ListeningRoomPlaybackEvent
    associatedtype Events: AsyncSequence<PlaybackEvent, Never>
    
    var events: Events { get }
    
    var isPlayingFromQueue: Bool { get }
    var playingItem: ListeningRoomPlayingItem? { get }
    var playbackState: ListeningRoomPlaybackState { get }
    var totalTime: TimeInterval? { get }
    var currentTime: TimeInterval? { get }
    var volume: Float { get }
    
    func setVolume(_ newVolume: Float) async throws -> Void
    func enqueue(_ itemToPlay: ListeningRoomPlayingItem, playNow: Bool) async throws -> Void
    func seek(toTime newTime: TimeInterval) async throws -> Void
    func pause() async throws -> Void
    func resume() async throws -> Void
    func stop() async throws -> Void
}
