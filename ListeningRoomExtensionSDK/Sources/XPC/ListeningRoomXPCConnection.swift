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

@Observable public final class ListeningRoomXPCConnection: CustomStringConvertible, @unchecked Sendable {
    static let logger = Logger(subsystem: "io.github.decarbonization.TheListeningRoom", category: "XPCConnection")
    
    public init(dispatcher: ListeningRoomXPCDispatcher) {
        self.dispatcher = dispatcher
        self.isPlaceholder = false
        self.stateLock = .init()
        self.withStateLock_connectionWaiters = []
    }
    
    internal init(_placeholder: Void) {
        self.dispatcher = ListeningRoomXPCDispatcher(role: .placeholder,
                                                     endpoints: [])
        self.isPlaceholder = true
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
    private let isPlaceholder: Bool
    private let stateLock: OSAllocatedUnfairLock<Void>
    private var withStateLock_connectionWaiters: [UnsafeContinuation<Void, any Error>]
    private var withStateLock_currentConnection: NSXPCConnection?
    
    /// Access the currently active XPC connection, if any.
    private var currentXPCConnection: NSXPCConnection? {
        access(keyPath: \.currentXPCConnection)
        stateLock.lock()
        defer {
            stateLock.unlock()
        }
        return withStateLock_currentConnection
    }
    
    /// Get the currently active XPC connection, optionally waiting for it to become available.
    ///
    /// - parameter wait: Whether to wait for the connection to become available.
    /// - returns: An active XPC connection.
    /// - throws: A `CocoaError` if the XPC connection could not be retrieved.
    private func xpcConnection(wait: Bool) async throws -> NSXPCConnection {
        guard !isPlaceholder else {
            throw CocoaError(.xpcConnectionInvalid, userInfo: [
                NSLocalizedDescriptionKey: "Cannot use placeholder connection",
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
    @discardableResult public func takeOwnership(of connection: NSXPCConnection) -> Bool {
        guard currentXPCConnection == nil && !isPlaceholder else {
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
    
    public func invalidate() {
        currentXPCConnection?.invalidate()
    }
    
    public func dispatch<Req: ListeningRoomXPCRequest>(_ request: Req, waitForConnection: Bool = true) async throws -> Req.Response {
        let connection = try await xpcConnection(wait: waitForConnection)
        let request = try _endpointEncode(request)
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
        return try _endpointDecode(from: response)
    }
    
    public var description: String {
        guard !isPlaceholder else {
            return "ListeningRoomXPCConnection(placeholder)"
        }
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
