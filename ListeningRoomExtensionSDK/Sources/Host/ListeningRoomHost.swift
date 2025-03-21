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

import SwiftUI

@MainActor @Observable internal final class ListeningRoomHost {
    init() {
        dispatcher = XPCDispatcher()
        deferredJobs = []
    }
    
    private let dispatcher: XPCDispatcher
    private var deferredJobs: [UnsafeContinuation<NSXPCConnection, Never>]
    private var _currentConnection: NSXPCConnection?
    
    /// Get the current connection or suspend until it becomes available.
    private var connection: NSXPCConnection {
        get async {
            if let _currentConnection {
                return _currentConnection
            } else {
                return await withUnsafeContinuation { continuation in
                    deferredJobs.append(continuation)
                }
            }
        }
    }
    
    internal func takeOwnership(of connection: NSXPCConnection) -> Bool {
        connection.exportedInterface = NSXPCInterface(with: XPCDispatcherProtocol.self)
        connection.exportedObject = dispatcher
        connection.remoteObjectInterface = NSXPCInterface(with: XPCDispatcherProtocol.self)
        
        connection.resume()
        
        _currentConnection = connection
        
        var drainedJobs = [UnsafeContinuation<NSXPCConnection, Never>]()
        swap(&drainedJobs, &deferredJobs)
        Task { [connection = SendUnchecked(connection)] in
            for job in drainedJobs {
                job.resume(returning: connection.unwrap)
            }
        }
        
        return true
    }
}

private struct SendUnchecked<Wrapped>: @unchecked Sendable {
    init(_ toWrap: Wrapped) {
        unwrap = toWrap
    }
    
    let unwrap: Wrapped
}
