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

@Suite struct ListeningRoomXPCDispatcherTests {
    @Test func noEndpointFound() async throws {
        let subject = ListeningRoomXPCDispatcher(role: .placeholder,
                                                 endpoints: [])
        await #expect(throws: CocoaError.self, performing: {
            try await withUnsafeThrowingContinuation { continuation in
                subject._dispatch(Data(), to: "notFound") { data, error in
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
        })
    }
    
    @Test func dispatch() async throws {
        let subject = ListeningRoomXPCDispatcher(role: .placeholder,
                                                 endpoints: [SquareEndpoint()])
        let request = try _endpointEncode(Square(value: 10))
        let responseData = try await withUnsafeThrowingContinuation { continuation in
            subject._dispatch(request, to: Square.endpoint) { data, error in
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
        let response = try _endpointDecode(Double.self, from: responseData)
        #expect(response == 100)
    }
}

private struct Square: ListeningRoomXPCRequest {
    typealias Response = Double
    
    var value: Double
}

private struct SquareEndpoint: ListeningRoomXPCEndpoint {
    func callAsFunction(_ request: Square) async throws -> Double {
        pow(request.value, 2)
    }
}
