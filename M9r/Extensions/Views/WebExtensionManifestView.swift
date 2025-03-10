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

import SwiftUI

struct WebExtensionManifestView: View {
    let manifest: WebExtension.Manifest
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(verbatim: manifest.shortName ?? manifest.name)
                .font(.callout)
                .foregroundStyle(.primary)
            Text(verbatim: manifest.versionName ?? manifest.version)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let permissions = manifest.permissions {
                Divider()
                
                Text("Required Permissions")
                    .font(.caption)
                    .foregroundStyle(.primary)
                
                ForEach(permissions, id: \.rawValue) { permission in
                    Text(verbatim: permission.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}
