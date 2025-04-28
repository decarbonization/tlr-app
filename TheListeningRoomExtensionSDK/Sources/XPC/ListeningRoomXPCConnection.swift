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

@Observable internal final class ListeningRoomXPCConnection: CustomStringConvertible, @unchecked Sendable {
    static let logger = Logger(subsystem: "io.github.decarbonization.TheListeningRoom", category: "XPCConnection")
    
    static let placeholder = ListeningRoomXPCConnection(role: .placeholder, endpoints: [])
    
    init(role: ListeningRoomXPCRole,
         endpoints: [any ListeningRoomXPCEndpoint] = []) {
        self.dispatcher = ListeningRoomXPCDispatcher(role: role,
                                                     endpoints: endpoints)
        self.stateLock = .init()
        self.withStateLock_connectionWaiters = []
    }
    
    deinit {
        if stateLock.lockIfAvailable() {
            let connectionWaiters = Array(withStateLock_connectionWaiters)
            withStateLock_connectionWaiters.removeAll()
            stateLock.unlock()
            Task { @MainActor in
                for connectionWaiter in connectionWaiters {
                    connectionWaiter.resume(throwing: CocoaError(.xpcConnectionInvalid))
                }
            }
        }
    }
    
    private let dispatcher: ListeningRoomXPCDispatcher
    private let stateLock: OSAllocatedUnfairLock<Void>
    private var withStateLock_connectionWaiters: [UnsafeContinuation<Void, any Error>]
    private var withStateLock_currentConnection: (any NSXPCConnectionLike)?
    
    /// Access the currently active XPC connection, if any.
    private var currentXPCConnection: (any NSXPCConnectionLike)? {
        access(keyPath: \.currentXPCConnection)
        stateLock.lock()
        defer {
            stateLock.unlock()
        }
        return withStateLock_currentConnection
    }
    
    var endpoints: [any ListeningRoomXPCEndpoint] {
        get {
            dispatcher.endpoints
        }
        set {
            dispatcher.endpoints = newValue
        }
    }
    
    /// Get the currently active XPC connection, optionally waiting for it to become available.
    ///
    /// - parameter wait: Whether to wait for the connection to become available.
    /// - returns: An active XPC connection.
    /// - throws: A `CocoaError` if the XPC connection could not be retrieved.
    private func xpcConnection(wait: Bool) async throws -> any NSXPCConnectionLike {
        guard dispatcher.role != .placeholder else {
            throw CocoaError(.xpcConnectionInvalid, userInfo: [
                NSLocalizedDescriptionKey: "Cannot communicate over placeholder",
            ])
        }
        repeat {
            if let currentXPCConnection {
                return currentXPCConnection
            }
            if !wait {
                throw CocoaError(.xpcConnectionInvalid)
            }
            try await withUnsafeThrowingContinuation { continuation in
                stateLock.lock()
                withStateLock_connectionWaiters.append(continuation)
                stateLock.unlock()
            }
        } while true
    }
    
    /// Take ownership of an XPC connection, configuring it to work with the Listening Room extension communication protocol.
    ///
    /// - parameter connection: An XPC connection to take ownership of.
    /// - returns: `true` if ownership was taken of the connection; `false` otherwise.
    @discardableResult func takeOwnership(of connection: NSXPCConnectionLike) -> Bool {
        guard currentXPCConnection == nil else {
            return false
        }
        
        connection.exportedInterface = NSXPCInterface(with: ListeningRoomXPCDispatcherProtocol.self)
        connection.exportedObject = dispatcher
        connection.remoteObjectInterface = NSXPCInterface(with: ListeningRoomXPCDispatcherProtocol.self)
        connection.interruptionHandler = { [weak self] in
            self?.xpcConnectionInterrupted()
        }
        connection.invalidationHandler = { [weak self] in
            self?.xpcConnectionInvalidated()
        }
        
        connection.resume()
        
        var connectionWaiters = [UnsafeContinuation<Void, any Error>]()
        stateLock.lock()
        withStateLock_currentConnection = connection
        swap(&connectionWaiters, &withStateLock_connectionWaiters)
        stateLock.unlock()
        
        Task { @MainActor in
            for connectionWaiter in connectionWaiters {
                connectionWaiter.resume()
            }
            
            withMutation(keyPath: \.currentXPCConnection) {
                // Do nothing.
            }
        }
        
        Self.logger.info("\(String(describing: self)) resumed")
        
        return true
    }
    
    /// Handle the XPC connection being interrupted due to the remote process exiting or crashing.
    ///
    /// The existing connection object may be used to re-establish communication with the remote process.
    private func xpcConnectionInterrupted() {
        Self.logger.info("\(String(describing: self)) interrupted")
    }
    
    /// Handle the XPC connection being invalidated.
    ///
    /// The existing connection object may not be used to re-establish communication with the remote process.
    private func xpcConnectionInvalidated() {
        Self.logger.error("\(String(describing: self)) invalidated")
        stateLock.lock()
        withStateLock_currentConnection = nil
        stateLock.unlock()
    }
    
    func invalidate() {
        currentXPCConnection?.invalidate()
    }
    
    func ping(waitForConnection: Bool = true) async throws {
        let connection = try await xpcConnection(wait: waitForConnection)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            let remoteDispatcher = connection.remoteObjectProxyWithErrorHandler { error in
                continuation.resume(throwing: error)
            } as! ListeningRoomXPCDispatcherProtocol
            remoteDispatcher._ping { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func post<E: ListeningRoomXPCEvent>(_ event: E, waitForConnection: Bool = true) async throws {
        let connection = try await xpcConnection(wait: waitForConnection)
        let event = try _encode(event)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            let remoteDispatcher = connection.remoteObjectProxyWithErrorHandler { error in
                continuation.resume(throwing: error)
            } as! ListeningRoomXPCDispatcherProtocol
            remoteDispatcher._post(event, with: E.name) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func receive<E: ListeningRoomXPCEvent>(_ eventType: E.Type) -> some (AsyncSequence<E, any Error> & Sendable) {
        dispatcher.events
            .filter {
                $0.name == E.name
            }
            .map {
                try _decode(E.self, from: $0.event)
            }
    }
    
    func dispatch<Req: ListeningRoomXPCRequest>(_ request: Req, waitForConnection: Bool = true) async throws -> Req.Response {
        let connection = try await xpcConnection(wait: waitForConnection)
        let request = try _encode(request)
        let response: Data = try await withCheckedThrowingContinuation { continuation in
            let remoteDispatcher = connection.remoteObjectProxyWithErrorHandler { error in
                continuation.resume(throwing: error)
            } as! ListeningRoomXPCDispatcherProtocol
            remoteDispatcher._dispatch(request, to: Req.endpoint) { data, error in
                switch (data, error) {
                case (let data?, nil):
                    continuation.resume(returning: data)
                case (nil, let error?):
                    continuation.resume(throwing: error)
                default:
                    continuation.resume(throwing: CocoaError(.xpcConnectionReplyInvalid, userInfo: [
                        NSLocalizedDescriptionKey: "Endpoint replied with neither response nor error",
                    ]))
                }
            }
        }
        return try _decode(from: response)
    }
    
    var description: String {
        var currentConnectionDescription = "(unknown)"
        if stateLock.lockIfAvailable() {
            if let withStateLock_currentConnection {
                currentConnectionDescription = String(describing: withStateLock_currentConnection)
            } else {
                currentConnectionDescription = "nil"
            }
            stateLock.unlock()
        }
        return "ListeningRoomXPCConnection(\(currentConnectionDescription))"
    }
}

/// Protocol over the interface of `NSXPCConnection` to make ``ListeningRoomXPCConnection`` testable.
protocol NSXPCConnectionLike: AnyObject {
    var exportedInterface: NSXPCInterface? { get set }
    var exportedObject: Any? { get set }
    var remoteObjectInterface: NSXPCInterface? { get set }
    var interruptionHandler: (() -> Void)? { get set }
    var invalidationHandler: (() -> Void)? { get set }
    
    func remoteObjectProxyWithErrorHandler(_ handler: @escaping (any Error) -> Void) -> Any
    
    func resume() -> Void
    func invalidate() -> Void
}

extension NSXPCConnection: NSXPCConnectionLike {
}
