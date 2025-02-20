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
@preconcurrency import SFBAudioEngine

final class SFBAudioEnginePlayer: NSObject, Player, AudioPlayer.Delegate {
    override init() {
        let (stream, continuation) = AsyncStream.makeStream(of: PlayerEvent.self)
        audioPlayer = AudioPlayer()
        eventSink = continuation
        events = stream
        
        super.init()
        
        audioPlayer.delegate = self
    }
    
    private let audioPlayer: AudioPlayer
    private let eventSink: AsyncStream<PlayerEvent>.Continuation
    
    // MARK: - Player
    
    let events: AsyncStream<PlayerEvent>
    
    var playbackState: PlayerPlaybackState {
        switch audioPlayer.playbackState {
        case .paused:
            return .paused
        case .playing:
            return .playing
        case .stopped:
            return .stopped
        @unknown default:
            fatalError("Unknown playback state \(audioPlayer.playbackState.rawValue)")
        }
    }
    
    var totalTime: TimeInterval? {
        audioPlayer.totalTime
    }
    
    var currentTime: TimeInterval? {
        audioPlayer.currentTime
    }
    
    var volume: Float {
        audioPlayer.volume
    }
    
    func setVolume(_ newVolume: Float) async throws {
        try audioPlayer.setVolume(newVolume)
    }
    
    func play(_ itemURL: URL, startingAt startTime: TimeInterval) async throws {
        try audioPlayer.enqueue(itemURL, immediate: true)
        try await seek(toTime: startTime)
        try audioPlayer.play()
    }
    
    func seek(toTime newTime: TimeInterval) async throws {
        if !audioPlayer.seek(time: newTime) {
            throw PlayerError.couldNotSeek(to: newTime)
        }
    }
    
    func pause() async throws {
        audioPlayer.pause()
    }
    
    func resume() async throws {
        audioPlayer.resume()
    }
    
    func stop() async throws {
        audioPlayer.stop()
        audioPlayer.clearQueue()
    }
    
    // MARK: - AudioPlayer.Delegate
    
    func audioPlayer(_ audioPlayer: AudioPlayer, playbackStateChanged playbackState: AudioPlayer.PlaybackState) {
        eventSink.yield(.playbackStateDidChange)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, nowPlayingChanged nowPlaying: (any PCMDecoding)?) {
        eventSink.yield(.playingItemDidChange)
    }
    
    func audioPlayer(_ audioPlayer: AudioPlayer, encounteredError error: any Error) {
        eventSink.yield(.encounteredError(error))
    }
    
    func audioPlayerEndOfAudio(_ audioPlayer: AudioPlayer) {
        eventSink.yield(.endOfAudio)
    }
}
