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

public struct ListeningRoomExtensionHostView: View {
    public init(process: ListeningRoomExtensionProcess,
                sceneID: String) {
        self.process = process
        self.sceneID = sceneID
    }
    
    private let process: ListeningRoomExtensionProcess
    private let sceneID: String
    
    public var body: some View {
        _ListeningRoomExtensionHostContent(process: process,
                                           sceneID: sceneID)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension View {
    @ViewBuilder public func listeningRoomHostEndpoint(_ endpoint: some ListeningRoomXPCEndpoint) -> some View {
        transformEnvironment(\._listeningRoomHostEndpoints) { endpoints in
            endpoints.append(endpoint)
        }
    }
    
    @ViewBuilder public func listeningRoomHostPoster(_ publisher: some ListeningRoomXPCPoster) -> some View {
        transformEnvironment(\._listeningRoomHostPosters) { publishers in
            publishers.append(publisher)
        }
    }
}

extension EnvironmentValues {
    @Entry fileprivate var _listeningRoomHostEndpoints = [any ListeningRoomXPCEndpoint]()
    @Entry fileprivate var _listeningRoomHostPosters = [any ListeningRoomXPCPoster]()
}

private struct _ListeningRoomExtensionHostContent: NSViewControllerRepresentable {
    let process: ListeningRoomExtensionProcess
    let sceneID: String
    
    @MainActor final class Coordinator: NSObject, EXHostViewControllerDelegate {
        let extensionScene = XPCConnection(role: .hostView)
        let posterSubscriber = AsyncSubscriber()
        var posters = [any ListeningRoomXPCPoster]() {
            didSet {
                guard hasPostersChanged(oldValue, from: posters) else {
                    return
                }
                posterSubscriber.deactivateAll()
                func subscribe(to poster: some ListeningRoomXPCPoster) {
                    posterSubscriber.activate(consuming: poster.activate()) { [weak extensionScene] event, _ in
                        do {
                            try await extensionScene?.post(event, waitForConnection: false)
                        } catch {
                            
                        }
                    }
                }
                for poster in posters {
                    subscribe(to: poster)
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
        let hostViewController = EXHostViewController()
        hostViewController.delegate = context.coordinator
        return hostViewController
    }
    
    func updateNSViewController(_ hostViewController: EXHostViewController, context: Context) {
        context.coordinator.extensionScene.endpoints = context.environment._listeningRoomHostEndpoints
        context.coordinator.posters = context.environment._listeningRoomHostPosters
        
        let oldConfiguration = hostViewController.configuration
        if oldConfiguration?.appExtension != process.identity || oldConfiguration?.sceneID != sceneID {
            hostViewController.configuration = EXHostViewController.Configuration(appExtension: process.identity,
                                                                                  sceneID: sceneID)
        }
    }
}

private func hasPostersChanged(_ oldValue: [any ListeningRoomXPCPoster], from newValue: [any ListeningRoomXPCPoster]) -> Bool {
    oldValue.count != newValue.count || !oldValue.elementsEqual(newValue) { lhs, rhs in
        type(of: lhs) == type(of: rhs)
    }
}
