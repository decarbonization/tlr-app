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
    /// Signals that the playback state of an engine has changed and the player
    /// should synchronize its state to match.
    ///
    /// An engine should sink this event in **all** instances where
    /// its `playbackState` property changes. Failure to do so will
    /// cause the player's user interface to fall out of sync.
    case playbackStateDidChange
    
    /// Signals that the item playing in an engine has changed and the player
    /// should synchronize its state to match.
    ///
    /// An engine should sink this event in **all** instances where
    /// its `playingItem` property changes. Failure to do so will
    /// cause the player's user interface to fall out of sync.
    case playingItemChanged
    
    case encounteredError(domain: String, code: Int, userInfo: [String: AnyCodable] = [:])
    
    /// Signals that a playback engine has reached the end of its available audio,
    /// and the host player should look for another item to play.
    ///
    /// If a playback engine maintains its own internal queue, for example to play an unbound
    /// source of audio like a radio station, it should only sink this event in the event that source
    /// has been exhausted. Otherwise, the engine will have its playback interrupted by the player
    /// looking for another source.
    ///
    /// - parameter lastItem: The last item that was played by the engine, if applicable.
    case endOfAudio(lastItem: ListeningRoomPlayingItem?)
    
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
    
    var playingItem: ListeningRoomPlayingItem? { get }
    var playbackState: ListeningRoomPlaybackState { get }
    var totalTime: TimeInterval? { get }
    var currentTime: TimeInterval? { get }
    var volume: Float { get }
    
    func setVolume(_ newVolume: Float) async throws -> Void
    
    /// Enqueue an item to in order to play it with this engine.
    ///
    /// The following behavior is prescribed for the `playNow` parameter:
    ///
    /// - if `playNow == true`: The engine is expected to begin the process of playing
    ///   the item before returning, interrupting any other engine which may be playing. The engine
    ///   can generally expect it will have priority and be able to successfully interrupt. The playback
    ///   state of the engine should ideally be `playing` once this method returns.
    /// - if `playNow == false`: The engine is expected to set up all of the infrastructure
    ///   needed to play the item, possibly preloading a stream. It must be possible to start playback
    ///   of the item with a subsequent call to `resume()`. The playback state of the engine should
    ///   ideally be `paused` once this method returns.
    ///
    /// - parameter itemToPlay: The item to play, typically from the library,
    /// but may be from other source like a streaming music service being wrapped
    /// by an extension.
    /// - parameter playNow: Whether to immediately start playback of the item.
    func enqueue(_ itemToPlay: ListeningRoomPlayingItem, playNow: Bool) async throws -> Void
    
    /// Skip the currently playing item in the engine's queue to play the previous one.
    ///
    /// An engine which plays a single item at a time may simply return `false`
    /// in its implementation of this method. It is only intended to be implemented
    /// by engines which play audio from a source other than the library.
    func skipPreviousInQueue() async throws -> Bool
    
    /// Skip the currently playing item in the engine's queue to play the next one.
    ///
    /// An engine which plays a single item at a time may simply return `false`
    /// in its implementation of this method. It is only intended to be implemented
    /// by engines which play audio from a source other than the library.
    func skipNextInQueue() async throws -> Bool
    func seek(toTime newTime: TimeInterval) async throws -> Void
    func pause() async throws -> Void
    func resume() async throws -> Void
    func stop() async throws -> Void
}
