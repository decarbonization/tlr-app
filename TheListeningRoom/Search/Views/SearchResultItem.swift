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

struct SearchResultItem: View {
    init(result: ListeningRoomSearchResult) {
        self.result = result
    }
    
    private let result: ListeningRoomSearchResult
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack {
            if let image = result.artwork?.image(in: modelContext) {
                image
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 3.0))
            }
            VStack(alignment: .leading) {
                if let primaryTitle = result.primaryTitle {
                    Text(verbatim: primaryTitle)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .allowsHitTesting(false)
                }
                if let secondaryTitle = result.secondaryTitle {
                    Text(verbatim: secondaryTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .allowsHitTesting(false)
                }
                if let tertiaryTitle = result.tertiaryTitle {
                    Text(verbatim: tertiaryTitle)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}
