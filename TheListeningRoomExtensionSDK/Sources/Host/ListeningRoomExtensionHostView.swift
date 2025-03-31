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

public enum ListeningRoomExtensionHostViewEvent: Sendable {
    case willActivate(extensionScene: ListeningRoomXPCConnection)
    case activate(extensionScene: ListeningRoomXPCConnection)
    case deactivate(error: (any Error)?)
}

public struct ListeningRoomExtensionHostView<Placeholder: View>: View {
    public typealias Event = ListeningRoomExtensionHostViewEvent
    
    public init(identity: AppExtensionIdentity,
                sceneID: String,
                @ViewBuilder placeholder: @escaping () -> Placeholder,
                onEvent: @escaping (Event) -> Void) {
        self.identity = identity
        self.sceneID = sceneID
        self.placeholder = placeholder
        self.onEvent = onEvent
    }
    
    private let identity: AppExtensionIdentity
    private let sceneID: String
    private let placeholder: () -> Placeholder
    private let onEvent: (Event) -> Void
    
    public var body: some View {
        _ListeningRoomExtensionHostContent(identity: identity,
                                           sceneID: sceneID,
                                           placeholder: placeholder,
                                           onEvent: onEvent)
    }
}

private struct _ListeningRoomExtensionHostContent<Placeholder: View>: NSViewControllerRepresentable {
    typealias Event = ListeningRoomExtensionHostViewEvent
    
    let identity: AppExtensionIdentity
    let sceneID: String
    let placeholder: () -> Placeholder
    let onEvent: (Event) -> Void
    
    final class Coordinator: NSObject, EXHostViewControllerDelegate {
        init(onEvent: @escaping (Event) -> Void) {
            self.extensionScene = ListeningRoomXPCConnection(
                ListeningRoomXPCDispatcher(role: .hostView)
                    .installEndpoint(ListeningRoomRemotePingEndpoint())
            )
            self.onEvent = onEvent
        }
        
        let extensionScene: ListeningRoomXPCConnection
        var onEvent: (Event) -> Void
        
        func hostViewControllerDidActivate(_ viewController: EXHostViewController) {
            do {
                onEvent(.willActivate(extensionScene: extensionScene))
                extensionScene.takeOwnership(of: try viewController.makeXPCConnection())
                Task {
                    do {
                        // NOTE: Scene connection is lazily initialized
                        let _ = try await extensionScene.dispatch(.ping)
                        onEvent(.activate(extensionScene: extensionScene))
                    } catch {
                        onEvent(.deactivate(error: error))
                    }
                }
            } catch {
                onEvent(.deactivate(error: error))
            }
        }
        
        func hostViewControllerWillDeactivate(_ viewController: EXHostViewController, error: (any Error)?) {
            extensionScene.invalidate()
            onEvent(.deactivate(error: error))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onEvent: onEvent)
    }
    
    func makeNSViewController(context: Context) -> EXHostViewController {
        context.coordinator.onEvent = onEvent
        
        let hostViewController = EXHostViewController()
        hostViewController.delegate = context.coordinator
        hostViewController.placeholderView = NSHostingView(rootView: placeholder())
        hostViewController.configuration = EXHostViewController.Configuration(appExtension: identity,
                                                                              sceneID: sceneID)
        return hostViewController
    }
    
    func updateNSViewController(_ hostViewController: EXHostViewController, context: Context) {
        context.coordinator.onEvent = onEvent
        
        hostViewController.placeholderView = NSHostingView(rootView: placeholder())
        hostViewController.configuration = EXHostViewController.Configuration(appExtension: identity,
                                                                              sceneID: sceneID)
    }
}
