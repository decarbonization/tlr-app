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

import ExtensionFoundation
import ExtensionKit
import os
import SwiftUI

public struct ListeningRoomExtensionHostView<Placeholder: View>: View {
    public init(identity: AppExtensionIdentity,
                sceneID: String,
                @ViewBuilder placeholder: @escaping () -> Placeholder,
                endpoints: @escaping @autoclosure () -> [any ListeningRoomXPCEndpoint],
                updateContext: @escaping (ListeningRoomXPCContext) -> Void) {
        self.identity = identity
        self.sceneID = sceneID
        self.placeholder = placeholder
        self.endpoints = endpoints
        self.updateContext = updateContext
    }
    
    private let identity: AppExtensionIdentity
    private let sceneID: String
    private let placeholder: () -> Placeholder
    private let endpoints: () -> [any ListeningRoomXPCEndpoint]
    private let updateContext: (ListeningRoomXPCContext) -> Void
    
    public var body: some View {
        _ListeningRoomExtensionHostContent(identity: identity,
                                           sceneID: sceneID,
                                           placeholder: placeholder,
                                           endpoints: endpoints,
                                           updateContext: updateContext)
    }
}

private struct _ListeningRoomExtensionHostContent<Placeholder: View>: NSViewControllerRepresentable {
    let identity: AppExtensionIdentity
    let sceneID: String
    let placeholder: () -> Placeholder
    let endpoints: () -> [any ListeningRoomXPCEndpoint]
    let updateContext: (ListeningRoomXPCContext) -> Void
    
    final class Coordinator: NSObject, EXHostViewControllerDelegate {
        init(endpoints: () -> [any ListeningRoomXPCEndpoint]) {
            context = ListeningRoomXPCContext()
            extensionScene = ListeningRoomXPCConnection(dispatcher: ListeningRoomXPCDispatcher(role: .hostView,
                                                                                               context: context,
                                                                                               endpoints: endpoints() + [ListeningRoomRemotePingEndpoint()]))
        }
        
        let context: ListeningRoomXPCContext
        let extensionScene: ListeningRoomXPCConnection
        
        func hostViewControllerDidActivate(_ viewController: EXHostViewController) {
            do {
                extensionScene.takeOwnership(of: try viewController.makeXPCConnection())
                Task {
                    do {
                        // NOTE: Scene connection is lazily initialized
                        let _ = try await extensionScene.dispatch(.ping)
                    } catch {
                        Logger.uiExtension.error("Could not activate connection to \(viewController), reason: \(error)")
                    }
                }
            } catch {
                Logger.uiExtension.error("Could not connect to \(viewController), reason: \(error)")
            }
        }
        
        func hostViewControllerWillDeactivate(_ viewController: EXHostViewController, error: (any Error)?) {
            extensionScene.invalidate()
            if let error {
                Logger.uiExtension.error("Lost connection to \(viewController), reason: \(error)")
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(endpoints: endpoints)
    }
    
    func makeNSViewController(context: Context) -> EXHostViewController {
        let hostViewController = EXHostViewController()
        hostViewController.delegate = context.coordinator
        updateContext(context.coordinator.context)
        hostViewController.placeholderView = NSHostingView(rootView: placeholder())
        hostViewController.configuration = EXHostViewController.Configuration(appExtension: identity,
                                                                              sceneID: sceneID)
        return hostViewController
    }
    
    func updateNSViewController(_ hostViewController: EXHostViewController, context: Context) {
        updateContext(context.coordinator.context)
        hostViewController.placeholderView = NSHostingView(rootView: placeholder())
        hostViewController.configuration = EXHostViewController.Configuration(appExtension: identity,
                                                                              sceneID: sceneID)
    }
}
