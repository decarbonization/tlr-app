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

final class SFBAudioEnginePlayer: NSObject, AudioPlayer.Delegate, Player {
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
    
    let events: AsyncStream<PlayerEvent>
    
    var playbackState: PlayerPlaybackState {
        fatalError()
    }
    
    var totalTime: TimeInterval {
        fatalError()
    }
    
    var currentTime: TimeInterval {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }
    
    var volume: Float {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }
    
    func enqueue(_ url: URL) async throws {
        fatalError()
    }
    
    func play() async throws {
        fatalError()
    }
    
    func pause() async throws {
        fatalError()
    }
    
    func resume() async throws {
        fatalError()
    }
    
    func stop() async throws {
        fatalError()
    }
    
    func clearQueue() async throws {
        fatalError()
    }
}
