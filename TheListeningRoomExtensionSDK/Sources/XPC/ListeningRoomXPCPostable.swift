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

/// A value which can be posted from an extension to a host, or from a host to an extension.
public protocol ListeningRoomXPCPostable: Codable, Sendable {
    /// The unique name of the postable value, defaults to the qualified name of the type.
    static var name: String { get }
}

extension ListeningRoomXPCPostable {
    public static var name: String {
        String(reflecting: type(of: self))
    }
}

public protocol ListeningRoomXPCPoster: Sendable {
    associatedtype Value: ListeningRoomXPCPostable
    associatedtype Values: AsyncSequence<Value, Never> & Sendable
    
    @MainActor func activate() -> Values
}
