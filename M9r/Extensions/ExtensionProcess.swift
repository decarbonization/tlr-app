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

import AsyncAlgorithms
import ExtensionFoundation
import ExtensionKit
import ListeningRoomExtensionSDK
import os

@MainActor @Observable final class ExtensionProcess: Identifiable {
    static let logger = Logger(subsystem: "io.github.decarbonization.TheListeningRoom", category: "ExtensionProcess")
    
    init(launching identity: AppExtensionIdentity) async throws {
        self.identity = identity
        self.interruptions = AsyncChannel()
        let processConfiguration = AppExtensionProcess.Configuration(appExtensionIdentity: identity, onInterruption: { [interruptions] in
            Task {
                await interruptions.send(())
            }
        })
        self.process = try await AppExtensionProcess(configuration: processConfiguration)
        self.extensionMain = ListeningRoomXPCConnection(dispatcher: ListeningRoomXPCDispatcher(role: .hostMain,
                                                                                               endpoints: [ListeningRoomPostRemoteNotificationEndpoint(),
                                                                                                           ListeningRoomRemotePingEndpoint()]))
        extensionMain.takeOwnership(of: try process.makeXPCConnection())
        
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: PlayQueue.nowPlayingDidChange) {
                guard let self else {
                    break
                }
                do {
                    _ = try await self.extensionMain.dispatch(.postRemoteNotification(name: .ListeningRoomPlayQueueDidChange), waitForConnection: false)
                } catch {
                    
                }
            }
        }
        Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: PlayQueue.playbackStateDidChange) {
                guard let self else {
                    break
                }
                do {
                    _ = try await self.extensionMain.dispatch(.postRemoteNotification(name: .ListeningRoomPlayQueueDidChange), waitForConnection: false)
                } catch {
                    
                }
            }
        }
    }
    
    let identity: AppExtensionIdentity
    let interruptions: AsyncChannel<Void>
    let process: AppExtensionProcess
    let extensionMain: ListeningRoomXPCConnection
    
    nonisolated var id: String {
        identity.bundleIdentifier
    }
    
    var features: [ListeningRoomExtensionTopLevelFeature] {
        get async throws {
            try await extensionMain.dispatch(.features)
        }
    }
}
