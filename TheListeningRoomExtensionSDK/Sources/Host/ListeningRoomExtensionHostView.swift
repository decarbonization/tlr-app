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

public enum ListeningRoomExtensionHostViewEvent {
    case willConnect(ListeningRoomXPCConnection)
    case didConnect(ListeningRoomXPCConnection)
    case lostConnection(error: (any Error)?)
}

public struct ListeningRoomExtensionHostView<Placeholder: View>: View {
    public init(process: ListeningRoomExtensionProcess,
                sceneID: String,
                @ViewBuilder placeholder: @escaping () -> Placeholder,
                onEvent: @escaping @Sendable (ListeningRoomExtensionHostViewEvent) -> Void) {
        self.process = process
        self.sceneID = sceneID
        self.placeholder = placeholder
        self.onEvent = onEvent
    }
    
    private let process: ListeningRoomExtensionProcess
    private let sceneID: String
    private let placeholder: () -> Placeholder
    private let onEvent: @Sendable (ListeningRoomExtensionHostViewEvent) -> Void
    
    public var body: some View {
        _ListeningRoomExtensionHostContent(process: process,
                                           sceneID: sceneID,
                                           placeholder: placeholder,
                                           onEvent: onEvent)
    }
}

private struct _ListeningRoomExtensionHostContent<Placeholder: View>: NSViewControllerRepresentable {
    let process: ListeningRoomExtensionProcess
    let sceneID: String
    let placeholder: () -> Placeholder
    let onEvent: @Sendable (ListeningRoomExtensionHostViewEvent) -> Void
    
    final class Coordinator: NSObject, EXHostViewControllerDelegate {
        init(onEvent: @escaping @Sendable (ListeningRoomExtensionHostViewEvent) -> Void) {
            self.extensionScene = ListeningRoomXPCConnection(role: .hostView)
            self.onEvent = onEvent
        }
        
        let extensionScene: ListeningRoomXPCConnection
        var onEvent: @Sendable (ListeningRoomExtensionHostViewEvent) -> Void
        
        func hostViewControllerDidActivate(_ viewController: EXHostViewController) {
            do {
                onEvent(.willConnect(extensionScene))
                extensionScene.takeOwnership(of: try viewController.makeXPCConnection())
                Task {
                    do {
                        // NOTE: Scene connection is lazily initialized
                        let _ = try await extensionScene.ping()
                        onEvent(.didConnect(extensionScene))
                    } catch {
                        onEvent(.lostConnection(error: error))
                    }
                }
            } catch {
                onEvent(.lostConnection(error: error))
            }
        }
        
        func hostViewControllerWillDeactivate(_ viewController: EXHostViewController, error: (any Error)?) {
            extensionScene.invalidate()
            onEvent(.lostConnection(error: error))
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
        hostViewController.configuration = EXHostViewController.Configuration(appExtension: process.identity,
                                                                              sceneID: sceneID)
        return hostViewController
    }
    
    func updateNSViewController(_ hostViewController: EXHostViewController, context: Context) {
        context.coordinator.onEvent = onEvent
        
        hostViewController.placeholderView = NSHostingView(rootView: placeholder())
        hostViewController.configuration = EXHostViewController.Configuration(appExtension: process.identity,
                                                                              sceneID: sceneID)
    }
}
