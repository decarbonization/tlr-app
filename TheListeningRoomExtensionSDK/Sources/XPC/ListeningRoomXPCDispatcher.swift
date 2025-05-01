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

internal import AsyncAlgorithms
import Foundation
import os

internal final class ListeningRoomXPCDispatcher: NSObject, Sendable {
    init(role: ListeningRoomXPCRole,
         endpoints: [any ListeningRoomXPCEndpoint]) {
        self.role = role
        var endpointsByName = [String: any ListeningRoomXPCEndpoint]()
        func name<E: ListeningRoomXPCEndpoint>(of endpoint: E) -> String {
            E.Request.endpoint
        }
        for endpoint in endpoints {
            endpointsByName[name(of: endpoint)] = endpoint
        }
        self._endpointsByName = .init(initialState: endpointsByName)
        self.incomingPosts = AsyncChannel()
    }
    
    let role: ListeningRoomXPCRole
    private let _endpointsByName: OSAllocatedUnfairLock<[String: any ListeningRoomXPCEndpoint]>
    
    internal let incomingPosts: AsyncChannel<(event: Data, name: String)>
    
    var endpoints: [any ListeningRoomXPCEndpoint] {
        get {
            _endpointsByName.withLock { endpointsByName in
                [any ListeningRoomXPCEndpoint](endpointsByName.values)
            }
        }
        set {
            var newEndpointsByName = [String: any ListeningRoomXPCEndpoint]()
            func name<E: ListeningRoomXPCEndpoint>(of endpoint: E) -> String {
                E.Request.endpoint
            }
            for endpoint in newValue {
                newEndpointsByName[name(of: endpoint)] = endpoint
            }
            _endpointsByName.withLock { [newEndpointsByName] endpointsByName in
                endpointsByName = newEndpointsByName
            }
        }
    }
    
    override var description: String {
        let endpointNames = _endpointsByName.withLockIfAvailable { $0.keys.joined(separator: ", ") } ?? "?"
        return "ListeningRoomXPCDispatcher(role: \(role), endpoints: [\(endpointNames)])"
    }
}

@objc(_ListeningRoomXPCDispatcher) internal protocol ListeningRoomXPCDispatcherProtocol: NSObjectProtocol {
    func _ping(replyHandler: @escaping @Sendable ((any Error)?) -> Void) -> Void
    
    func _post(_ event: Data,
               with name: String,
               replyHandler: @escaping @Sendable ((any Error)?) -> Void) -> Void
    
    func _dispatch(_ request: Data,
                   to endpoint: String,
                   replyHandler: @escaping @Sendable (Data?, (any Error)?) -> Void) -> Void
}

extension ListeningRoomXPCDispatcher: ListeningRoomXPCDispatcherProtocol {
    internal func _ping(replyHandler: @escaping @Sendable ((any Error)?) -> Void) {
        Task {
            replyHandler(nil)
        }
    }
    
    internal func _post(_ event: Data,
                        with name: String,
                        replyHandler: @escaping @Sendable ((any Error)?) -> Void) {
        Task {
            await incomingPosts.send((event, name))
            replyHandler(nil)
        }
    }
    
    internal func _dispatch(_ request: Data,
                            to endpoint: String,
                            replyHandler: @escaping @Sendable (Data?, (any Error)?) -> Void) {
        Task {
            do {
                guard let endpoint = _endpointsByName.withLock({ $0[endpoint] }) else {
                    throw CocoaError(.featureUnsupported, userInfo: [
                        NSLocalizedDescriptionKey: "No <\(endpoint)> endpoint found",
                    ])
                }
                func forward<Endpoint: ListeningRoomXPCEndpoint>(_ request: Data, to endpoint: Endpoint) async throws -> Data {
                    let request = try _decode(Endpoint.Request.self, from: request)
                    let response = try await endpoint(request)
                    return try _encode(response)
                }
                let response = try await forward(request, to: endpoint)
                replyHandler(response, nil)
            } catch {
                replyHandler(nil, error)
            }
        }
    }
}
