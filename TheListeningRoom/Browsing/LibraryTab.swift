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

import SwiftUI

struct LibraryTab: Identifiable {
    struct ID: RawRepresentable, Hashable {
        var rawValue: String
        
        static let artists = Self(rawValue: "artists")
        static let albums = Self(rawValue: "albums")
        static let songs = Self(rawValue: "songs")
        static let playlists = Self(rawValue: "playlists")
        static let extensions = Self(rawValue: "extensions")
    }
    
    init(id: ID,
         @ViewBuilder content: @escaping () -> some View,
         @ViewBuilder label: @escaping () -> some View) {
        self.id = id
        self.content = { AnyView(erasing: content()) }
        self.label = { AnyView(erasing: label()) }
    }
    
    var id: ID
    var content: () -> AnyView
    var label: () -> AnyView
}
