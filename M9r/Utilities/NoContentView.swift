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

struct NoContentView<Content: View>: View {
    init(_ content: any StringProtocol) where Content == Text {
        self.init(content: { Text(content) })
    }
    
    init(_ key: LocalizedStringKey) where Content == Text {
        self.init(content: { Text(key) })
    }
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    private let content: () -> Content
    
    var body: some View {
        VStack(alignment: .center) {
            content()
                .multilineTextAlignment(.center)
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
