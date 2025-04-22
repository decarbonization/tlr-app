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
import os
import SwiftData
import SwiftUI

@Observable public final class ListeningRoomPlayQueue: Sendable {
    public init(connection: ListeningRoomXPCConnection) {
        self.connection = connection
        self._state = .init(initialState: .empty)
    }
    
    private let connection: ListeningRoomXPCConnection
    private let _state: OSAllocatedUnfairLock<ListeningRoomHostPlayQueueState>
    
    private var state: ListeningRoomHostPlayQueueState {
        access(keyPath: \.state)
        return _state.withLock { $0 }
    }
    
    public var playbackState: ListeningRoomPlaybackState {
        state.playbackState
    }
    
    public var playingItemIndex: Int? {
        state.playingItemIndex
    }
    
    public var items: [PersistentIdentifier] {
        state.items
    }
    
    public func pause() async throws -> Bool {
        try await connection.dispatch(ListeningRoomHostPlayQueueAction.pause)
    }
    
    public func resume() async throws -> Bool {
        try await connection.dispatch(ListeningRoomHostPlayQueueAction.resume)
    }
    
    public func previousTrack() async throws -> Bool {
        try await connection.dispatch(ListeningRoomHostPlayQueueAction.previousTrack)
    }
    
    public func nextTrack() async throws -> Bool {
        try await connection.dispatch(ListeningRoomHostPlayQueueAction.nextTrack)
    }
    
    public func refresh() async throws {
        let newState = try await connection.dispatch(ListeningRoomHostPlayQueueGetState())
        _state.withLock { state in
            state = newState
        }
        withMutation(keyPath: \.state) {
            // Do nothing.
        }
    }
}

extension EnvironmentValues {
    @Entry public var listeningRoomPlayQueue = ListeningRoomPlayQueue(connection: ListeningRoomXPCConnection(_placeholder: ()))
}
