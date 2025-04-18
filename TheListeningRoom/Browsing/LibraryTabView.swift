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

struct LibraryTabView: View {
    init(content: [LibraryTab]) {
        self.content = content
        _selection = .init(wrappedValue: content[0].id)
    }
    
    private let content: [LibraryTab]
    @State private var selection: LibraryTab.ID
    
    var body: some View {
        _LibraryTabViewContent(content: content,
                               selection: $selection)
        .toolbar {
            Picker(selection: $selection) {
                ForEach(content) { tab in
                    tab.label()
                }
            } label: {
                Text("Browse")
            }
            .labelStyle(.titleAndIcon)
            .pickerStyle(.segmented)
        }
    }
}

private struct _LibraryTabViewContent: NSViewRepresentable {
    let content: [LibraryTab]
    @Binding var selection: LibraryTab.ID
    
    func makeNSView(context: Context) -> NSTabView {
        let nsTabView = NSTabView()
        nsTabView.tabViewType = .noTabsNoBorder
        nsTabView.tabViewBorderType = .none
        nsTabView.tabViewItems = content.map { tab in
            let newTabViewItem = NSTabViewItem(identifier: tab.id)
            newTabViewItem.view = NSHostingView(rootView: tab.content())
            return newTabViewItem
        }
        nsTabView.selectTabViewItem(withIdentifier: selection)
        return nsTabView
    }
    
    func updateNSView(_ nsTabView: NSTabView, context: Context) {
        nsTabView.selectTabViewItem(withIdentifier: selection)
    }
}
