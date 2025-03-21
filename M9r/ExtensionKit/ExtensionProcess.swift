/*
 * M9r
 * Copyright (C) 2025  MAINTAINERS
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import ExtensionFoundation
import ExtensionKit
import ListeningRoomExtensionSDK
import os

@MainActor @Observable final class ExtensionProcess: Identifiable {
    init(launching identity: AppExtensionIdentity) async throws {
        self.identity = identity
        let processConfiguration = AppExtensionProcess.Configuration(appExtensionIdentity: identity,
                                                                     onInterruption: { [weak self] in self?.interrupted() })
        self.process = try await AppExtensionProcess(configuration: processConfiguration)
        self.connection = try process.makeXPCConnection()
        connection.exportedInterface = NSXPCInterface(with: XPCDispatcherProtocol.self)
        connection.exportedObject = XPCDispatcher()
        connection.remoteObjectInterface = NSXPCInterface(with: XPCDispatcherProtocol.self)
        connection.resume()
    }
    
    let identity: AppExtensionIdentity
    var process: AppExtensionProcess!
    var connection: NSXPCConnection!
    
    private func interrupted() {
        ExtensionManager.logger.error("*** App extension process \(self.identity.bundleIdentifier) was interrupted")
    }
    
    nonisolated var id: String {
        identity.bundleIdentifier
    }
    
    var features: [ListeningRoomExtensionFeature] {
        get async throws {
            try await dispatch(ListeningRoomExtensionGetFeatures(), over: connection)
        }
    }
}
