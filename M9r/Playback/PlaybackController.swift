//
//  PlaybackController.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/22/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import SwiftUI
import SFBAudioEngine
import os

@Observable final class PlaybackController: @unchecked Sendable {
    private enum DelegateEvent: @unchecked Sendable {
        case playbackStateChanged(AudioPlayer.PlaybackState)
        case nowPlayingChanged((any PCMDecoding)?)
    }
    
    private final class Delegate: NSObject, AudioPlayer.Delegate {
        init(_ observer: @escaping @Sendable (DelegateEvent) -> Void) {
            self.observer = observer
        }
        
        private let observer: @Sendable (DelegateEvent) -> Void
        
        // MARK: - AudioPlayer.Delegate
        
        func audioPlayer(_ audioPlayer: AudioPlayer,
                         playbackStateChanged playbackState: AudioPlayer.PlaybackState) {
            observer(.playbackStateChanged(playbackState))
        }
        
        func audioPlayer(_ audioPlayer: AudioPlayer,
                         nowPlayingChanged nowPlaying: (any PCMDecoding)?) {
            observer(.nowPlayingChanged(nowPlaying))
        }
    }
    
    private static let logger = Logger()
    
    init() {
        audioPlayer = AudioPlayer()
        delegate = Delegate { [weak self] event in
            self?.consumeDelegateEvent(event)
        }
        audioPlayer.delegate = delegate
    }
    
    private let audioPlayer: AudioPlayer
    private var delegate: Delegate?
    
    var playbackState: AudioPlayer.PlaybackState {
        access(keyPath: \.playbackState)
        return audioPlayer.playbackState
    }
    
    var nowPlaying: (any PCMDecoding)? {
        access(keyPath: \.nowPlaying)
        return audioPlayer.nowPlaying
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
    
    private func consumeDelegateEvent(_ event: DelegateEvent) {
        switch event {
        case .playbackStateChanged(let newPlaybackState):
            withMutation(keyPath: \.playbackState) {
                Self.logger.info("\(String(describing: self)).playbackState = \(newPlaybackState.rawValue)")
            }
        case .nowPlayingChanged(let newNowPlaying):
            withMutation(keyPath: \.nowPlaying) {
                Self.logger.info("\(String(describing: self)).nowPlaying = \(String(describing: newNowPlaying))")
            }
        }
    }
}
