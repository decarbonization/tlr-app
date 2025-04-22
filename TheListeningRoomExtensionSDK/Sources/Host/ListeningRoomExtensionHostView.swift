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
    public init(process: ListeningRoomExtensionProcess,
                sceneID: String,
                @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.process = process
        self.sceneID = sceneID
        self.placeholder = placeholder
    }
    
    private let process: ListeningRoomExtensionProcess
    private let sceneID: String
    private let placeholder: () -> Placeholder
    
    public var body: some View {
        _ListeningRoomExtensionHostContent(process: process,
                                           sceneID: sceneID,
                                           placeholder: placeholder)
    }
}

extension View {
    @ViewBuilder public func listeningRoomHostEndpoint(_ endpoint: some ListeningRoomXPCEndpoint) -> some View {
        transformEnvironment(\._listeningRoomHostEndpoints) { endpoints in
            endpoints.append(endpoint)
        }
    }
    
    @ViewBuilder public func listeningRoomHostEventPublisher(_ publisher: some ListeningRoomXPCEventPublisher) -> some View {
        transformEnvironment(\._listeningRoomHostEventPublishers) { publishers in
            publishers.append(publisher)
        }
    }
}

extension EnvironmentValues {
    @Entry internal var _listeningRoomHostEndpoints = [any ListeningRoomXPCEndpoint]()
    @Entry internal var _listeningRoomHostEventPublishers = [any ListeningRoomXPCEventPublisher]()
}

private struct _ListeningRoomExtensionHostContent<Placeholder: View>: NSViewControllerRepresentable {
    let process: ListeningRoomExtensionProcess
    let sceneID: String
    let placeholder: () -> Placeholder
    
    final class Coordinator: NSObject, EXHostViewControllerDelegate {
        let extensionScene = ListeningRoomXPCConnection(role: .hostView)
        let subscriber = AsyncSubscriber()
        var publishers = [any ListeningRoomXPCEventPublisher]() {
            willSet {
                subscriber.deactivateAll()
            }
            didSet {
                func subscribe(to publisher: some ListeningRoomXPCEventPublisher) {
                    subscriber.activate(consuming: publisher.subscribe()) { [weak extensionScene] event, _ in
                        Task {
                            try await extensionScene?.post(event, waitForConnection: false)
                        }
                    }
                }
                for publisher in publishers {
                    subscribe(to: publisher)
                }
            }
        }
        
        func hostViewControllerDidActivate(_ viewController: EXHostViewController) {
            do {
                extensionScene.takeOwnership(of: try viewController.makeXPCConnection())
                Task {
                    do {
                        // NOTE: Scene connection is lazily initialized
                        try await extensionScene.ping()
                    } catch {
                    }
                }
            } catch {
            }
        }
        
        func hostViewControllerWillDeactivate(_ viewController: EXHostViewController, error: (any Error)?) {
            extensionScene.invalidate()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSViewController(context: Context) -> EXHostViewController {
        context.coordinator.extensionScene.endpoints = context.environment._listeningRoomHostEndpoints
        context.coordinator.publishers = context.environment._listeningRoomHostEventPublishers
        
        let hostViewController = EXHostViewController()
        hostViewController.delegate = context.coordinator
        hostViewController.placeholderView = NSHostingView(rootView: placeholder())
        hostViewController.configuration = EXHostViewController.Configuration(appExtension: process.identity,
                                                                              sceneID: sceneID)
        return hostViewController
    }
    
    func updateNSViewController(_ hostViewController: EXHostViewController, context: Context) {
        context.coordinator.extensionScene.endpoints = context.environment._listeningRoomHostEndpoints
        context.coordinator.publishers = context.environment._listeningRoomHostEventPublishers
        
        hostViewController.placeholderView = NSHostingView(rootView: placeholder())
        hostViewController.configuration = EXHostViewController.Configuration(appExtension: process.identity,
                                                                              sceneID: sceneID)
    }
}
