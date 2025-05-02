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
@preconcurrency import ExtensionKit
import Foundation

@MainActor @Observable public final class ListeningRoomExtensionProcess: Identifiable {
    public init(launching identity: AppExtensionIdentity,
                endpoints: [any ListeningRoomXPCEndpoint]) async throws {
        self.identity = identity
        self._interruptions = AsyncChannel()
        let processConfiguration = AppExtensionProcess.Configuration(appExtensionIdentity: identity, onInterruption: { @Sendable [_interruptions] in
            Task {
                await _interruptions.send(())
            }
        })
        self.process = try await AppExtensionProcess(configuration: processConfiguration)
        self.extensionMain = ListeningRoomXPCConnection(role: .hostMain,
                                                        endpoints: endpoints)
        extensionMain.takeOwnership(of: try process.makeXPCConnection())
    }
    
    internal let identity: AppExtensionIdentity
    internal let _interruptions: AsyncChannel<Void>
    internal let process: AppExtensionProcess
    internal let extensionMain: ListeningRoomXPCConnection
    
    public nonisolated var id: String {
        identity.bundleIdentifier
    }
    
    public var localizedName: String {
        identity.localizedName
    }
    
    public var interruptions: some AsyncSequence<Void, Never> {
        _interruptions
    }
    
    public var features: [ListeningRoomTopLevelFeature] {
        get async throws {
            try await extensionMain.dispatch(.features)
        }
    }
    
    public func post(_ event: some ListeningRoomXPCPostable) async throws {
        try await extensionMain.post(event)
    }
    
    public func receive<E: ListeningRoomXPCPostable>(_ eventType: E.Type) -> some AsyncSequence<E, any Error> {
        extensionMain.posts(of: eventType)
    }
}
