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

struct ExtensionsSourceListSection: View {
    @State private var identities = [AppExtensionIdentity]()
    
    var body: some View {
        Section("Extensions") {
            ForEach(identities, id: \.bundleIdentifier) { identity in
                NavigationLink {
                    ListeningRoomExtensionHostView(identity: identity,
                                                   placeholder: { ProgressView() })
                } label: {
                    Label(identity.localizedName, systemImage: "puzzlepiece.extension")
                }
                .navigationTitle(identity.localizedName)
            }
        }
        .task {
            do {
                let matches = try AppExtensionIdentity.matching(appExtensionPointIDs: "io.github.decarbonization.M9r.service.extension")
                for await newMatches in matches {
                    identities = newMatches
                }
            } catch {
                
            }
        }
    }
}
