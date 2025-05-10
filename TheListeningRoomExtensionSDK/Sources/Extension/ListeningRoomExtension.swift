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
import ExtensionFoundation
import ExtensionKit
import SwiftUI

public protocol ListeningRoomExtension: AppExtension where Configuration == AppExtensionSceneConfiguration {
    associatedtype Features: ListeningRoomFeature
    associatedtype Body: AppExtensionScene
    
    @MainActor @ListeningRoomFeatureBuilder var features: Features { get }
    @MainActor @AppExtensionSceneBuilder var body: Body { get }
}

extension ListeningRoomExtension {
    @MainActor public var configuration: Configuration {
        AppExtensionSceneConfiguration(body, configuration: ExtensionConfiguration(self))
    }
}

internal final class ExtensionConfiguration<E: ListeningRoomExtension>: AppExtensionConfiguration {
    init(_ appExtension: E) {
        self.appExtension = appExtension
        self.hostMain = XPCConnection(role: .extensionMain,
                                      endpoints: [ExtensionGetFeaturesEndpoint(appExtension)])
    }
    
    private let appExtension: E
    private let hostMain: XPCConnection
    
    func accept(connection: NSXPCConnection) -> Bool {
        hostMain.takeOwnership(of: connection)
    }
}
