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
import os
import SFBAudioEngine
import SwiftData

extension WebExtensionEventName {
    static let playbackStateChanged = Self(rawValue: "playbackstatechanged")
    static let nowPlayingChanged = Self(rawValue: "nowplayingchanged")
}

struct PlayQueueService: WebExtensionService {
    enum Message: Codable {
        case previous
        case next
        case pause
        case resume
        case play
        case getState
        case getQueue
    }
    
    enum Reply: Codable {
        case state(playbackState: PlayerPlaybackState,
                   nowPlaying: PersistentIdentifier?)
        case queue(items: [PersistentIdentifier],
                   playingIndex: Int?)
        
        static func state(of playQueue: PlayQueue) -> Self {
            .state(playbackState: .from(playQueue.playbackState),
                   nowPlaying: playQueue.playingItem?.id)
        }
        
        static func queue(of playQueue: PlayQueue) -> Self {
            .queue(items: playQueue.items.map { $0.id },
                   playingIndex: playQueue.playingIndex)
        }
    }
    
    private final class NotificationPublisher: NSObject, WebExtensionEventPublisher {
        init(playQueue: PlayQueue,
             eventSink: any WebExtensionServiceEventSink) {
            self.eventSink = eventSink
            
            super.init()
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(playbackStateDidChange(_:)),
                                                   name: PlayQueue.playbackStateDidChange,
                                                   object: playQueue)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(nowPlayingDidChange(_:)),
                                                   name: PlayQueue.nowPlayingDidChange,
                                                   object: playQueue)
        }
        
        deinit {
            stop()
        }
        
        private let eventSink: any WebExtensionServiceEventSink
        
        func stop() {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc private func playbackStateDidChange(_ notification: Notification) {
            guard let playQueue = notification.object as? PlayQueue else {
                return
            }
            
            Task {
                await eventSink.dispatchEvent(of: .playbackStateChanged,
                                              with: PlayerPlaybackState.from(playQueue.playbackState))
            }
        }
        
        @objc private func nowPlayingDidChange(_ notification: Notification) {
            guard let playQueue = notification.object as? PlayQueue else {
                return
            }
            
            Task {
                await eventSink.dispatchEvent(of: .nowPlayingChanged,
                                              with: playQueue.playingItem?.id)
            }
        }
    }
    
    static var name: String {
        "playQueue"
    }
    
    static var requiredPermissions: Set<WebExtension.Permission> {
        [.playQueue]
    }
    
    init(playQueue: PlayQueue) {
        self.playQueue = playQueue
    }
    
    let playQueue: PlayQueue
    
    func beginDispatchingEvents(into eventSink: some WebExtensionServiceEventSink) -> any WebExtensionEventPublisher {
        NotificationPublisher(playQueue: playQueue,
                              eventSink: eventSink)
    }
    
    func receive(_ message: Message, with context: WebExtensionServiceContext) async throws -> Reply {
        try await MainActor.run {
            switch message {
            case .previous:
                try playQueue.previousTrack()
                return .state(of: playQueue)
            case .next:
                try playQueue.nextTrack()
                return .state(of: playQueue)
            case .pause:
                playQueue.pause()
                return .state(of: playQueue)
            case .resume:
                playQueue.resume()
                return .state(of: playQueue)
            case .play:
                if playQueue.playbackState == .stopped && !playQueue.items.isEmpty {
                    try playQueue.play(playQueue.items)
                }
                return .state(of: playQueue)
            case .getState:
                return .state(of: playQueue)
            case .getQueue:
                return .queue(of: playQueue)
            }
        }
    }
}
