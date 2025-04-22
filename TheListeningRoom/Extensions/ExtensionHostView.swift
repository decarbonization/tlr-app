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
    init(process: ListeningRoomExtensionProcess,
         sceneID: String,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.process = process
        self.sceneID = sceneID
        self.placeholder = placeholder
    }
    
    init(process: ListeningRoomExtensionProcess,
         sceneID: String)
    where Placeholder == ProgressView<EmptyView, EmptyView> {
        self.init(process: process,
                  sceneID: sceneID,
                  placeholder: { ProgressView<EmptyView, EmptyView>() })
    }
    
    private let process: ListeningRoomExtensionProcess
    private let sceneID: String
    private let placeholder: () -> Placeholder
    @Environment(Player.self) private var player
    
    var body: some View {
        ListeningRoomExtensionHostView(process: process,
                                       sceneID: sceneID,
                                       placeholder: placeholder)
        .listeningRoomHostEndpoint(PlayQueueActionEndpoint(player: player))
        .listeningRoomHostEndpoint(PlayQueueGetStateEndpoint(player: player))
        .listeningRoomHostEventPublisher(PlayerStateChangePublisher(player: player))
    }
}
