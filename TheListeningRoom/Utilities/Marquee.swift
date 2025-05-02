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

struct Marquee<Content: View>: View {
    private struct LayoutState: Equatable {
        init(_ geometry: ScrollGeometry) {
            contentSize = geometry.contentSize
            isContentTooLarge = geometry.contentSize.width > geometry.containerSize.width
        }
        
        var contentSize: CGSize
        var isContentTooLarge: Bool
    }
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    private let content: () -> Content
    @State private var startDate = Date.now
    @State private var contentSize = CGSize.zero
    @State private var isContentTooLarge = false
    @Environment(\.marqueeSpeed) private var speed
    @Environment(\.marqueeSpacing) private var spacing
    
    var body: some View {
        TimelineView(.animation(paused: !isContentTooLarge)) { context in
            ScrollView(.horizontal) {
                content()
                    .lineLimit(1, reservesSpace: true)
                    .fixedSize()
                    .compositingGroup()
                    .distortionEffect(ShaderLibrary.marquee(.float(context.date.timeIntervalSince(startDate)),
                                                            .float(speed),
                                                            .float(contentSize.width + spacing)),
                                      maxSampleOffset: .zero,
                                      isEnabled: isContentTooLarge)
            }
            .scrollDisabled(true)
            .scrollIndicators(.hidden, axes: .horizontal)
            .onScrollGeometryChange(for: LayoutState.self) { geometry in
                LayoutState(geometry)
            } action: { _, layoutState in
                contentSize = layoutState.contentSize
                isContentTooLarge = layoutState.isContentTooLarge
            }
        }
    }
}

extension View {
    func marqueeSpeed(_ newValue: CGFloat) -> some View {
        environment(\.marqueeSpeed, newValue)
    }
    
    func marqueeSpacing(_ newValue: CGFloat) -> some View {
        environment(\.marqueeSpacing, newValue)
    }
}

extension EnvironmentValues {
    @Entry fileprivate var marqueeSpeed: CGFloat = 0.2
    @Entry fileprivate var marqueeSpacing: CGFloat = 32
}
