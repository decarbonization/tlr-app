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

public protocol ListeningRoomXPCRequest<Response>: Codable, Sendable {
    associatedtype Response: Codable & Sendable
    
    /// The name of the endpoint which will receive this request. Defaults to the unqualified type name of the request.
    static var endpoint: String { get }
}

extension ListeningRoomXPCRequest {
    public static var endpoint: String {
        String("\(self)".split(separator: ".").last!)
    }
}

/// The absence of a response from an XPC request which only triggers a side effect.
@frozen public struct Nothing: Codable, Sendable {
    public static let nothing = Self()
}

internal func _decode<T: Codable>(_ type: T.Type = T.self, from request: Data) throws -> T {
    let jsonDecoder = JSONDecoder()
    jsonDecoder.dataDecodingStrategy = .base64
    jsonDecoder.dateDecodingStrategy = .iso8601
    jsonDecoder.keyDecodingStrategy = .useDefaultKeys
    jsonDecoder.allowsJSON5 = false
    return try jsonDecoder.decode(type, from: request)
}

internal func _encode(_ value: some Codable) throws -> Data {
    let jsonEncoder = JSONEncoder()
    jsonEncoder.dataEncodingStrategy = .base64
    jsonEncoder.dateEncodingStrategy = .iso8601
    jsonEncoder.keyEncodingStrategy = .useDefaultKeys
    return try jsonEncoder.encode(value)
}
