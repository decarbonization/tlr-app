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

import ExtensionKit
import ListeningRoomExtensionSDK
import SwiftUI

public struct ListeningRoomExtensionHostView<Placeholder: View>: View {
    public init(identity: AppExtensionIdentity,
                @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.identity = identity
        self.placeholder = placeholder
    }
    
    private let identity: AppExtensionIdentity
    private let placeholder: () -> Placeholder
    
    public var body: some View {
        _ListeningRoomExtensionHostContent(identity: identity,
                                           placeholder: placeholder)
    }
}

private struct _ListeningRoomExtensionHostContent<Placeholder: View>: NSViewControllerRepresentable {
    let identity: AppExtensionIdentity
    let placeholder: () -> Placeholder
    
    final class Coordinator: NSObject, EXHostViewControllerDelegate {
        func hostViewControllerDidActivate(_ viewController: EXHostViewController) {
        }
        
        func hostViewControllerWillDeactivate(_ viewController: EXHostViewController, error: (any Error)?) {
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeNSViewController(context: Context) -> EXHostViewController {
        let hostViewController = EXHostViewController()
        hostViewController.delegate = context.coordinator
        hostViewController.placeholderView = NSHostingView(rootView: placeholder())
        hostViewController.configuration = EXHostViewController.Configuration(appExtension: identity,
                                                                              sceneID: _ListeningRoomExtensionSceneName)
        return hostViewController
    }
    
    func updateNSViewController(_ hostViewController: EXHostViewController, context: Context) {
        
    }
}
