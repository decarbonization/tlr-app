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

import MediaPlayer
import os
import SFBAudioEngine
import SwiftUI

@Observable final class PlayQueue: @unchecked Sendable {
    enum RepeatMode: CaseIterable, Equatable, Codable {
        case none
        case all
        case one
    }
    
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
            Task { @MainActor in
                observer(.playbackStateChanged(playbackState))
            }
        }
        
        func audioPlayer(_ audioPlayer: AudioPlayer,
                         nowPlayingChanged nowPlaying: (any PCMDecoding)?) {
            Task { @MainActor in
                observer(.nowPlayingChanged(nowPlaying))
            }
        }
        
        func audioPlayerEndOfAudio(_ audioPlayer: AudioPlayer) {
            Task { @MainActor in
                observer(.endOfAudio)
            }
        }
    }
    
    static let log = Logger(subsystem: "io.github.decarbonization.M9r", category: "PlayQueue")
    
    init() {
        audioPlayer = AudioPlayer()
        items = []
        repeatMode = .none
        delegate = Delegate { [weak self] event in
            self?.consumeDelegateEvent(event)
        }
        audioPlayer.delegate = delegate
        
        let remoteCommandCenter = MPRemoteCommandCenter.shared()
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else {
                return .commandFailed
            }
            if self.playbackState == .paused {
                self.resume()
                return .success
            } else if self.playbackState == .playing {
                self.pause()
                return .success
            } else if self.playbackState == .stopped && !items.isEmpty {
                do {
                    try play(itemAt: 0)
                    return .success
                } catch {
                    PlayQueue.log.warning("Could not start playback for media key, reason: \(error)")
                    return .commandFailed
                }
            } else {
                return .noSuchContent
            }
        }
        remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
            do {
                try self?.previousTrack()
                return .success
            } catch {
                PlayQueue.log.warning("Could not skip back for media key, reason: \(error)")
                return .commandFailed
            }
            
        }
        remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
            do {
                try self?.nextTrack()
                return .success
            } catch {
                PlayQueue.log.warning("Could not skip forward for media key, reason: \(error)")
                return .commandFailed
            }
        }
    }
    
    private let audioPlayer: AudioPlayer
    private var delegate: Delegate?
    private var heartBeat: Timer? {
        didSet {
            oldValue?.invalidate()
        }
    }
    
    private(set) var items: [Song]
    private(set) var playingIndex: Int?
    var playingItem: Song? {
        guard let playingIndex else {
            return nil
        }
        return items[playingIndex]
    }
    
    var repeatMode: RepeatMode
    
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
                    Self.log.warning("Could not seek to new time <\(newValue)>")
                }
            }
        }
    }
    
    var volume: Float {
        get {
            access(keyPath: \.volume)
            return audioPlayer.volume
        }
        set {
            withMutation(keyPath: \.volume) {
                do {
                    try audioPlayer.setVolume(newValue)
                } catch {
                    Self.log.warning("Could not update volume, reason: \(error)")
                    TaskErrors.all.present(error)
                }
            }
        }
    }
    
    private func play(itemAt index: Int) throws {
        let item = items[index]
        let itemURL = try item.currentURL()
        guard itemURL.startAccessingSecurityScopedResource() else {
            throw CocoaError(.fileReadNoPermission, userInfo: [
                NSLocalizedDescriptionKey: "Could not extend sandbox for file <\(itemURL)>",
                NSURLErrorKey: itemURL
            ])
        }
        try audioPlayer.enqueue(itemURL, immediate: true)
        if !audioPlayer.seek(time: item.startTime) {
            Self.log.warning("Could not seek to startTime <\(item.startTime)>")
        }
        try audioPlayer.play()
        playingIndex = index
        heartBeat = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.withMutation(keyPath: \.currentTime) {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                    MPMediaItemPropertyMediaType: MPMediaType.music.rawValue,
                    MPMediaItemPropertyPlaybackDuration: item.endTime,
                    MPMediaItemPropertyTitle: item.title ?? "--",
                    MPMediaItemPropertyArtist: item.artist?.name ?? "--",
                    MPMediaItemPropertyAlbumTitle: item.album?.title ?? "--",
                ]
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
        switch repeatMode {
        case .none:
            return playingIndex > 0
        case .all,
             .one:
            return true
        }
    }
    
    func previousTrack() throws {
        guard let playingIndex else {
            return
        }
        if let currentTime = audioPlayer.currentTime, currentTime > 10 {
            audioPlayer.seek(time: 0)
        } else {
            switch repeatMode {
            case .none:
                if playingIndex > 0 {
                    try play(itemAt: playingIndex - 1)
                } else {
                    stop()
                }
            case .all:
                if playingIndex > 0 {
                    try play(itemAt: playingIndex - 1)
                } else {
                    try play(itemAt: items.count - 1)
                }
            case .one:
                try play(itemAt: playingIndex)
            }
        }
    }
    
    var canSkipNextTrack: Bool {
        guard let playingIndex else {
            return false
        }
        switch repeatMode {
        case .none:
            return playingIndex < (items.count - 1)
        case .all,
             .one:
            return true
        }
    }
    
    func nextTrack() throws {
        guard let playingIndex else {
            return
        }
        switch repeatMode {
        case .none:
            if playingIndex < (items.count - 1) {
                try play(itemAt: playingIndex + 1)
            } else {
                stop()
            }
        case .all:
            if playingIndex < (items.count - 1) {
                try play(itemAt: playingIndex + 1)
            } else {
                try play(itemAt: 0)
            }
        case .one:
            try play(itemAt: playingIndex)
        }
    }
    
    func pause() {
        audioPlayer.pause()
    }
    
    func resume() {
        audioPlayer.resume()
    }
    
    func stop() {
        guard let playingItem else {
            return
        }
        do {
            let itemURL = try playingItem.currentURL()
            itemURL.stopAccessingSecurityScopedResource()
        } catch {
            Self.log.warning("Could not close sandbox extension, reason: \(error)")
        }
        withMutation(keyPath: \.currentTime) {
            audioPlayer.stop()
            audioPlayer.clearQueue()
            playingIndex = nil
            heartBeat = nil
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }
    
    func relativePosition(of itemIndex: Int) -> ComparisonResult? {
        guard let playingIndex else {
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
    
    @discardableResult func withItems<R>(perform actions: (inout [Song]) throws -> R) rethrows -> R {
        let playingItem = playingItem
        var newItems = items // [#35] Must copy for stop to work.
        defer {
            if let playingItem {
                if let newPlayingIndex = newItems.firstIndex(where: { $0.id == playingItem.id }) {
                    playingIndex = newPlayingIndex
                } else {
                    stop()
                }
            }
            items = newItems
        }
        return try actions(&newItems)
    }
    
    private func consumeDelegateEvent(_ event: DelegateEvent) {
        switch event {
        case .playbackStateChanged(let newPlaybackState):
            withMutation(keyPath: \.playbackState) {
                Self.log.info("\(String(describing: self)).playbackState = \(newPlaybackState.rawValue)")
                switch newPlaybackState {
                case .playing:
                    MPNowPlayingInfoCenter.default().playbackState = .playing
                case .paused:
                    MPNowPlayingInfoCenter.default().playbackState = .paused
                case .stopped:
                    MPNowPlayingInfoCenter.default().playbackState = .stopped
                @unknown default:
                    MPNowPlayingInfoCenter.default().playbackState = .unknown
                }
            }
        case .nowPlayingChanged(_):
            withMutation(keyPath: \.totalTime) {
                // Do nothing
            }
        case .endOfAudio:
            do {
                try nextTrack()
            } catch {
                Self.log.error("Could not advance to next track, reason: \(error)")
                stop()
            }
        }
    }
}
