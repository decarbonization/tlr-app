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

struct PlayQueueService: WebExtensionService {
    struct Message: Codable {
        enum Command: String, Codable {
            case state
            case previous
            case next
            case pause
            case resume
        }
        
        var command: Command
    }
    
    struct Reply: Codable {
        var playbackState: PlayerPlaybackState
    }
    
    private final class NotificationPublisher: NSObject, WebExtensionEventPublisher {
        init(playQueue: PlayQueue,
             eventSink: any WebExtensionServiceEventSink) {
            self.eventSink = eventSink
            
            super.init()
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(didChange(_:)),
                                                   name: PlayQueue.playbackStateChanged,
                                                   object: playQueue)
        }
        
        deinit {
            stop()
        }
        
        private let eventSink: any WebExtensionServiceEventSink
        
        func stop() {
            NotificationCenter.default.removeObserver(self)
        }
        
        @objc private func didChange(_ notification: Notification) {
            guard let playQueue = notification.object as? PlayQueue else {
                return
            }
            
            Task {
                await eventSink.dispatchEvent(of: "playbackstatechanged",
                                              with: PlayerPlaybackState.from(playQueue.playbackState))
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
    
    func beginDispatchingEvents(into eventSink: any WebExtensionServiceEventSink) -> any WebExtensionEventPublisher {
        NotificationPublisher(playQueue: playQueue,
                              eventSink: eventSink)
    }
    
    func receive(_ message: Message, with context: WebExtensionServiceContext) async throws -> Reply {
        try await MainActor.run {
            switch message.command {
            case .state:
                break
            case .previous:
                try playQueue.previousTrack()
            case .next:
                try playQueue.nextTrack()
            case .pause:
                playQueue.pause()
            case .resume:
                playQueue.resume()
            }
        }
        return Reply(playbackState: .from(playQueue.playbackState))
    }
}
