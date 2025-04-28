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

import TheListeningRoomExtensionSDK
import SwiftUI

extension View {
    @ViewBuilder func searchSource(_ searchSource: some ListeningRoomSearchSource) -> some View {
        transformEnvironment(\.searchSources) { searchSources in
            searchSources.append(searchSource)
        }
    }
}

extension EnvironmentValues {
    @Entry fileprivate(set) var searchSources = [any ListeningRoomSearchSource]()
}
