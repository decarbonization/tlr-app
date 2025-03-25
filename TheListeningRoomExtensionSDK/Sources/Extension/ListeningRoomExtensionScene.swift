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

import ExtensionKit
import SwiftUI

public struct ListeningRoomExtensionScene<Content: View>: AppExtensionScene {
    public init(id: String,
                @ViewBuilder content: @escaping @MainActor () -> Content) {
        self.id = id
        self.content = content
    }
    
    public init(id: some RawRepresentable<String>,
                @ViewBuilder content: @escaping @MainActor () -> Content) {
        self.id = id.rawValue
        self.content = content
    }
    
    private let id: String
    private let content: @MainActor () -> Content
    private let hostView = ListeningRoomXPCConnection(dispatcher: ListeningRoomXPCDispatcher(role: .extensionScene,
                                                                                             endpoints: [ListeningRoomRemotePingEndpoint()]))
    
    public var body: some AppExtensionScene {
        PrimitiveAppExtensionScene(id: id) {
            content()
                .environment(\.listeningRoomPlayQueue, ListeningRoomPlayQueue(connection: hostView))
        } onConnection: { @Sendable connection in
            hostView.takeOwnership(of: connection)
        }
    }
}
