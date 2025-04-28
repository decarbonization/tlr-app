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

struct TablessView<TabIDs: Sequence, TabContent: View>: NSViewRepresentable {
    typealias TabID = TabIDs.Element
    
    init(_ tabIDs: TabIDs,
         selection: Binding<TabID>,
         @ViewBuilder content: @escaping (TabID) -> TabContent) {
        self.tabIDs = tabIDs
        self._selection = selection
        self.content = content
    }
    
    private let tabIDs: TabIDs
    @Binding private var selection: TabID
    private let content: (TabID) -> TabContent
    
    func makeNSView(context: Context) -> NSTabView {
        let nsTabView = NSTabView()
        nsTabView.tabViewType = .noTabsNoBorder
        nsTabView.tabViewBorderType = .none
        nsTabView.tabViewItems = tabIDs.map { tabID in
            let newTabViewItem = NSTabViewItem(identifier: tabID)
            newTabViewItem.view = NSHostingView(rootView: content(tabID))
            return newTabViewItem
        }
        nsTabView.selectTabViewItem(withIdentifier: selection)
        return nsTabView
    }
    
    func updateNSView(_ nsTabView: NSTabView, context: Context) {
        nsTabView.selectTabViewItem(withIdentifier: selection)
    }
}
