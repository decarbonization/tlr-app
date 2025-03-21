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

public func dispatch<Req: XPCRequest>(_ request: Req, over connection: NSXPCConnection) async throws -> Req.Response {
    let request = try _encode(request)
    let response: Data = try await withCheckedThrowingContinuation { continuation in
        let dispatcher = connection.remoteObjectProxyWithErrorHandler { error in
            continuation.resume(throwing: error)
        } as! XPCDispatcherProtocol
        dispatcher.dispatch(request, to: Req.endpoint) { data, error in
            switch (data, error) {
            case (let data?, nil):
                continuation.resume(returning: data)
            case (nil, let error?):
                continuation.resume(throwing: error)
            default:
                fatalError()
            }
        }
    }
    return try _decode(from: response)
}

@objc(LREXPCDispatcher) public protocol XPCDispatcherProtocol: NSObjectProtocol {
    func dispatch(_ request: Data,
                  to endpoint: String,
                  replyHandler: @escaping @Sendable (Data?, (any Error)?) -> Void) -> Void
}

public final class XPCDispatcher: NSObject, XPCDispatcherProtocol, Sendable {
    public init<each E: XPCEndpoint>(_ endpoint: repeat each E) {
        var endpoints = [String: any XPCEndpoint]()
        for endpoint in repeat (each endpoint) {
            endpoints[endpoint._name] = endpoint
        }
        self.endpoints = endpoints
    }
    
    private let endpoints: [String: any XPCEndpoint]
    
    public func dispatch(_ request: Data,
                         to endpoint: String,
                         replyHandler: @escaping @Sendable (Data?, (any Error)?) -> Void) {
        Task {
            do {
                guard let endpoint = endpoints[endpoint] else {
                    throw CocoaError(.featureUnsupported, userInfo: [
                        NSLocalizedDescriptionKey: "No <\(endpoint)> endpoint found",
                    ])
                }
                let response = try await endpoint(request)
                replyHandler(response, nil)
            } catch {
                replyHandler(nil, error)
            }
        }
    }
}

extension XPCEndpoint {
    fileprivate var _name: String {
        Self.Request.endpoint
    }
    
    @MainActor fileprivate func callAsFunction(_ request: Data) async throws -> Data {
        let request = try _decode(Request.self, from: request)
        let response = try await self(request)
        return try _encode(response)
    }
}

private func _decode<T: Codable>(_ type: T.Type = T.self, from request: Data) throws -> T {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.dataDecodingStrategy = .base64
    jsonDecoder.dateDecodingStrategy = .iso8601
    jsonDecoder.keyDecodingStrategy = .useDefaultKeys
    jsonDecoder.allowsJSON5 = false
    return try jsonDecoder.decode(type, from: request)
}

private func _encode(_ value: some Codable) throws -> Data {
    let jsonEncoder = JSONEncoder()
    jsonEncoder.dataEncodingStrategy = .base64
    jsonEncoder.dateEncodingStrategy = .iso8601
    jsonEncoder.keyEncodingStrategy = .useDefaultKeys
    return try jsonEncoder.encode(value)
}
