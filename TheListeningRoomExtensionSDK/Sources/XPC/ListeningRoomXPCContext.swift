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

public protocol ListeningRoomXPCContextKey<Value> {
    associatedtype Value: Sendable
    
    static var defaultValue: Value { get }
}

extension ListeningRoomXPCContextKey where Value: ExpressibleByNilLiteral {
    public static var defaultValue: Value {
        nil
    }
}

public final class ListeningRoomXPCContext: @unchecked Sendable {
    private struct _Key: Hashable, CustomStringConvertible {
        init<K: ListeningRoomXPCContextKey>(_ key: K.Type) {
            self.keyType = K.self
        }
        
        private let keyType: any ListeningRoomXPCContextKey.Type
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.keyType == rhs.keyType
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(keyType))
        }
        
        var description: String {
            "\(keyType)"
        }
    }
    
    public init() {
        stateLock = .init()
        withLock_values = [:]
    }
    
    public init(copying other: ListeningRoomXPCContext) {
        stateLock = .init()
        other.stateLock.lock()
        withLock_values = other.withLock_values
        other.stateLock.unlock()
    }
    
    private let stateLock: OSAllocatedUnfairLock<Void>
    private var withLock_values: [_Key: Any]
    
    public subscript<K: ListeningRoomXPCContextKey>(key: K.Type) -> K.Value {
        get {
            stateLock.lock()
            defer {
                stateLock.unlock()
            }
            guard let value = withLock_values[_Key(key)] as? K.Value else {
                return K.defaultValue
            }
            return value
        }
        set {
            stateLock.lock()
            defer {
                stateLock.unlock()
            }
            withLock_values[_Key(key)] = newValue
        }
    }
}
