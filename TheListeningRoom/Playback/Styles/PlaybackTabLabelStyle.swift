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

struct PlaybackTabLabelStyle: LabelStyle {
    init(isHighlighted: Bool) {
        self.isHighlighted = isHighlighted
    }
    
    private let isHighlighted: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center, spacing: 3) {
            configuration.icon
                .imageScale(.large)
            configuration.title
                .font(.footnote)
                .lineLimit(1)
        }
        .foregroundStyle(isHighlighted ? AnyShapeStyle(.accent) : AnyShapeStyle(.primary))
        .backgroundStyle(isHighlighted ? AnyShapeStyle(.thickMaterial) : AnyShapeStyle(.clear))
    }
}

extension LabelStyle where Self == PlaybackTabLabelStyle {
    static func playbackTabLabel(isHighlighted: Bool) -> Self {
        Self(isHighlighted: isHighlighted)
    }
}
