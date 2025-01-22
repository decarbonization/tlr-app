//
//  PlaybackController.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/22/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import SwiftUI
import SFBAudioEngine

@MainActor @Observable final class PlaybackController {
    init() {
        audioPlayer = AudioPlayer()
        delegate = .init()
        audioPlayer.delegate = delegate
    }
    
    private let audioPlayer: AudioPlayer
    private let delegate: PlaybackEvent.DelegateAdapter
    
    var events: some AsyncSequence<PlaybackEvent, Never> {
        AsyncStream { [delegate = self.delegate] continuation in
            let consumer = delegate.addConsumer { event in
                continuation.yield(event)
            }
            continuation.onTermination = { _ in
                delegate.removeConsumer(consumer)
            }
        }
    }
    
    var playbackState: AudioPlayer.PlaybackState {
        audioPlayer.playbackState
    }
    
    var nowPlaying: (any PCMDecoding)? {
        audioPlayer.nowPlaying
    }
    
    func play(_ song: LibrarySong) throws {
        try audioPlayer.play(song.file)
    }
    
    func pause() {
        audioPlayer.pause()
    }
    
    func resume() {
        audioPlayer.resume()
    }
    
    func stop() {
        audioPlayer.stop()
    }
}
