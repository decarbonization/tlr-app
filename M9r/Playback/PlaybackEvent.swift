//
//  PlaybackEvent.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/22/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import Foundation
import SFBAudioEngine

enum PlaybackEvent: @unchecked Sendable {
    case playbackStateChanged(AudioPlayer.PlaybackState)
    case nowPlayingChanged((any PCMDecoding)?)
    
    final class DelegateAdapter: NSObject, AudioPlayer.Delegate {
        final class Consumer {
            init(_ body: @escaping @Sendable (PlaybackEvent) -> Void) {
                self.body = body
            }
            
            let body: @Sendable (PlaybackEvent) -> Void
            
            func callAsFunction(_ event: PlaybackEvent) {
                body(event)
            }
        }
        
        override init() {
            consumers = .init(initialState: [])
        }
        
        private let consumers: OSAllocatedUnfairLock<[Consumer]>
        
        func addConsumer(_ body: @escaping @Sendable (PlaybackEvent) -> Void) -> Consumer {
            let newConsumer = Consumer(body)
            consumers.withLock { consumers in
                consumers.append(newConsumer)
            }
            return newConsumer
        }
        
        func removeConsumer(_ consumer: Consumer) {
            consumers.withLock { consumers in
                guard let toRemove = consumers.firstIndex(where: { $0 === consumer }) else {
                    return
                }
                consumers.remove(at: toRemove)
            }
        }
        
        private func notify(_ event: PlaybackEvent) {
            let toNotify = consumers.withLock { Array($0) }
            for consumer in toNotify {
                consumer(event)
            }
        }
        
        // MARK: - AudioPlayer.Delegate
        
        func audioPlayer(_ audioPlayer: AudioPlayer,
                         playbackStateChanged playbackState: AudioPlayer.PlaybackState) {
            notify(.playbackStateChanged(playbackState))
        }
        
        func audioPlayer(_ audioPlayer: AudioPlayer,
                         nowPlayingChanged nowPlaying: (any PCMDecoding)?) {
            notify(.nowPlayingChanged(nowPlaying))
        }
    }
}
