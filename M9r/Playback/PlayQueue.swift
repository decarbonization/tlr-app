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

import os
import SFBAudioEngine
import SwiftUI

@Observable final class PlayQueue: @unchecked Sendable {
    private enum DelegateEvent: @unchecked Sendable {
        case playbackStateChanged(AudioPlayer.PlaybackState)
        case nowPlayingChanged((any PCMDecoding)?)
        case endOfAudio
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
        
        func audioPlayerEndOfAudio(_ audioPlayer: AudioPlayer) {
            observer(.endOfAudio)
        }
    }
    
    static let log = Logger(subsystem: "io.github.decarbonization.M9r", category: "PlayQueue")
    
    init() {
        audioPlayer = AudioPlayer()
        items = []
        delegate = Delegate { [weak self] event in
            self?.consumeDelegateEvent(event)
        }
        audioPlayer.delegate = delegate
    }
    
    private let audioPlayer: AudioPlayer
    private var delegate: Delegate?
    private var heartBeat: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }
    
    private(set) var items: [Song]
    private var playingIndex: Int?
    var playingItem: Song? {
        guard let playingIndex else {
            return nil
        }
        return items[playingIndex]
    }
    
    var playbackState: AudioPlayer.PlaybackState {
        access(keyPath: \.playbackState)
        return audioPlayer.playbackState
    }
    
    var totalTime: TimeInterval {
        access(keyPath: \.totalTime)
        return audioPlayer.totalTime ?? 0
    }
    
    var currentTime: TimeInterval {
        get {
            access(keyPath: \.currentTime)
            return audioPlayer.currentTime ?? 0
        }
        set {
            withMutation(keyPath: \.currentTime) {
                if !audioPlayer.seek(time: newValue) {
                    
                }
            }
        }
    }
    
    private func play(itemAt index: Int) throws {
        let item = items[index]
        try withMutation(keyPath: \.totalTime) {
            try audioPlayer.play(item.currentURL())
        }
        playingIndex = index
        heartBeat = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.withMutation(keyPath: \.currentTime) {
                // Do nothing.
            }
        }
    }
    
    func play(_ newItems: [Song],
              startingAt startIndex: Int = 0) throws {
        stop()
        items = newItems
        guard !newItems.isEmpty else {
            return
        }
        try play(itemAt: startIndex)
    }
    
    var canSkipPreviousTrack: Bool {
        guard let playingIndex else {
            return false
        }
        return playingIndex > 0
    }
    
    func previousTrack() throws {
        guard let playingIndex,
              playingIndex > 0 else {
            return
        }
        if let currentTime = audioPlayer.currentTime, currentTime > 10 {
            audioPlayer.seek(time: 0)
        } else {
            try play(itemAt: playingIndex - 1)
        }
    }
    
    var canSkipNextTrack: Bool {
        guard let playingIndex else {
            return false
        }
        return playingIndex < (items.count - 1)
    }
    
    func nextTrack() throws {
        guard let playingIndex,
              playingIndex < (items.count - 1) else {
            return
        }
        try play(itemAt: playingIndex + 1)
    }
    
    func pause() {
        audioPlayer.pause()
    }
    
    func resume() {
        audioPlayer.resume()
    }
    
    func stop() {
        audioPlayer.stop()
        audioPlayer.clearQueue()
        playingIndex = nil
        heartBeat = nil
    }
    
    func relativeItemPosition(_ item: Song) -> ComparisonResult? {
        guard let playingIndex,
              let itemIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return nil
        }
        if itemIndex < playingIndex {
            return .orderedAscending
        } else if itemIndex > playingIndex {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }
    
    func moveItems(fromOffsets source: IndexSet, toOffset destination: Int) {
        let playingItem = playingItem
        items.move(fromOffsets: source, toOffset: destination)
        if let playingItem {
            playingIndex = items.firstIndex(where: { $0.id == playingItem.id })
        }
    }
    
    func removeItems(atOffsets toRemove: IndexSet) {
        if let playingIndex,
           toRemove.contains(playingIndex) {
            stop()
        }
        items.remove(atOffsets: toRemove)
    }
    
    private func consumeDelegateEvent(_ event: DelegateEvent) {
        switch event {
        case .playbackStateChanged(let newPlaybackState):
            withMutation(keyPath: \.playbackState) {
                Self.log.info("\(String(describing: self)).playbackState = \(newPlaybackState.rawValue)")
            }
        case .nowPlayingChanged(_):
            break
        case .endOfAudio:
            try! nextTrack()
        }
    }
}
