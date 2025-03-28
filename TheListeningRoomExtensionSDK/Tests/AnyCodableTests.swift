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

@testable import TheListeningRoomExtensionSDK
import Foundation
import Testing

@Suite struct AnyCodableTests {
    @Test func localUnwrap() throws {
        let container = AnyCodable(wrapping: 42 as Int64)
        #expect(try container.unwrap(Int64.self) == 42)
        #expect(throws: DecodingError.self, performing: {
            try container.unwrap(String.self)
        })
    }
    
    @Test func remoteUnwrap() throws {
        let specimen = AnyCodable(wrapping: 42 as Int64)
        let data = try _endpointEncode(specimen)
        let container = try _endpointDecode(AnyCodable.self, from: data)
        
        #expect(try container.unwrap(Int64.self) == 42)
        #expect(throws: DecodingError.self, performing: {
            try container.unwrap(String.self)
        })
    }
}
