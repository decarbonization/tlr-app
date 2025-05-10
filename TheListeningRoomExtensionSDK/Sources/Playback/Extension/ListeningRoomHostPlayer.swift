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
import SwiftUI

@Observable public final class ListeningRoomHostPlayer: Sendable {
    internal init(connection: XPCConnection) {
        self.connection = connection
        self.subscriber = AsyncSubscriber()
        self._state = .init(initialState: .empty)
        subscriber.activate(consuming: connection.posts(of: ListeningRoomPlayerState.self)) { [weak self] newState, _ in
            self?.state = newState
        }
    }
    
    private let connection: XPCConnection
    private let subscriber: AsyncSubscriber
    private let _state: OSAllocatedUnfairLock<ListeningRoomPlayerState>
    
    private var state: ListeningRoomPlayerState {
        get {
            access(keyPath: \.state)
            return _state.withLock { $0 }
        }
        set {
            _state.withLock { state in
                state = newValue
            }
            withMutation(keyPath: \.state) {
                // Do nothing.
            }
        }
    }
    
    public var playbackState: ListeningRoomPlaybackState {
        state.playbackState
    }
    
    public var playingItemIndex: Int? {
        state.playingItemIndex
    }
    
    public var items: [ListeningRoomID] {
        state.items
    }
    
    public func replaceQueue(withContentsOf newItemsIDs: [ListeningRoomID],
                             pinning nextItemID: ListeningRoomID? = nil) async throws {
        state = try await connection.dispatch(ListeningRoomHostPlayerAction.replaceQueue(newItemsIDs: newItemsIDs, nextItemID: nextItemID))
    }
    
    public func playItem(withID itemID: ListeningRoomID) async throws {
        state = try await connection.dispatch(ListeningRoomHostPlayerAction.play(item: itemID))
    }
    
    public func pause() async throws {
        state = try await connection.dispatch(ListeningRoomHostPlayerAction.pause)
    }
    
    public func resume() async throws {
        state = try await connection.dispatch(ListeningRoomHostPlayerAction.resume)
    }
    
    public func skipPrevious() async throws {
        state = try await connection.dispatch(ListeningRoomHostPlayerAction.skipPrevious)
    }
    
    public func skipNext() async throws {
        state = try await connection.dispatch(ListeningRoomHostPlayerAction.skipNext)
    }
}

extension EnvironmentValues {
    @Entry public var listeningRoomPlayer = ListeningRoomHostPlayer(connection: .placeholder)
}
