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

/// A container which can be used to send a type-erased value between an extension and host and vice versa.
public struct AnyCodable: Codable, Sendable {
    private enum _Value: @unchecked Sendable {
        case decoded(any Codable)
        case encoded(Data)
    }
    
    public init(wrapping value: any Codable) {
        if let value = value as? AnyCodable {
            _value = value._value
        } else {
            _value = .decoded(value)
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        _value = .encoded(try container.decode(Data.self))
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch _value {
        case .decoded(let value):
            try container.encode(_endpointEncode(value))
        case .encoded(let data):
            try container.encode(data)
        }
    }
    
    private let _value: _Value
    
    public func unwrap<T: Codable & Sendable>(_ type: T.Type = T.self) throws -> T {
        switch _value {
        case .decoded(let value):
            guard let value = value as? T else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [],
                                                                        debugDescription: "Value is not <\(type)>"))
            }
            return value
        case .encoded(let data):
            let value = try _endpointDecode(type, from: data)
            return value
        }
    }
}
