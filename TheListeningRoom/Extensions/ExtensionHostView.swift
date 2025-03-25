/*
 * The Listening Room Project
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

import ExtensionKit
import TheListeningRoomExtensionSDK
import SwiftUI

struct ExtensionHostView<Placeholder: View>: View {
    init(process: ExtensionProcess,
         sceneID: String,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.process = process
        self.sceneID = sceneID
        self.placeholder = placeholder
    }
    
    init(process: ExtensionProcess,
         sceneID: String) where Placeholder == ProgressView<EmptyView, EmptyView> {
        self.init(process: process, sceneID: sceneID, placeholder: { ProgressView<EmptyView, EmptyView>() })
    }
    
    private let process: ExtensionProcess
    private let sceneID: String
    private let placeholder: () -> Placeholder
    
    var body: some View {
        _ListeningRoomExtensionHostContent(process: process,
                                           sceneID: sceneID,
                                           placeholder: placeholder)
    }
}

private struct _ListeningRoomExtensionHostContent<Placeholder: View>: NSViewControllerRepresentable {
    let process: ExtensionProcess
    let sceneID: String
    let placeholder: () -> Placeholder
    @Environment(PlayQueue.self) private var playQueue
    
    final class Coordinator: NSObject, EXHostViewControllerDelegate {
        init(playQueue: PlayQueue) {
            extensionScene = ListeningRoomXPCConnection(dispatcher: ListeningRoomXPCDispatcher(role: .hostView,
                                                                                               endpoints: [PlayQueueActionEndpoint(playQueue),
                                                                                                           PlayQueueGetStateEndpoint(playQueue),
                                                                                                           ListeningRoomRemotePingEndpoint()]))
        }
        
        let extensionScene: ListeningRoomXPCConnection
        
        func hostViewControllerDidActivate(_ viewController: EXHostViewController) {
            do {
                extensionScene.takeOwnership(of: try viewController.makeXPCConnection())
                Task {
                    do {
                        // NOTE: Scene connection is lazily initialized
                        let _ = try await extensionScene.dispatch(.ping)
                    } catch {
                        ExtensionProcess.logger.error("Pinging extension scene failed \(viewController), reason: \(error)")
                    }
                }
            } catch {
                ExtensionProcess.logger.error("Could not establish extension scene connection to \(viewController), reason: \(error)")
            }
        }
        
        func hostViewControllerWillDeactivate(_ viewController: EXHostViewController, error: (any Error)?) {
            extensionScene.invalidate()
            if let error {
                ExtensionProcess.logger.error("Lost extension scene connection to \(viewController), reason: \(error)")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(playQueue: playQueue)
    }
    
    func makeNSViewController(context: Context) -> EXHostViewController {
        let hostViewController = EXHostViewController()
        hostViewController.delegate = context.coordinator
        hostViewController.placeholderView = NSHostingView(rootView: placeholder())
        hostViewController.configuration = EXHostViewController.Configuration(appExtension: process.identity,
                                                                              sceneID: sceneID)
        return hostViewController
    }
    
    func updateNSViewController(_ hostViewController: EXHostViewController, context: Context) {
        hostViewController.placeholderView = NSHostingView(rootView: placeholder())
        hostViewController.configuration = EXHostViewController.Configuration(appExtension: process.identity,
                                                                              sceneID: sceneID)
    }
}
