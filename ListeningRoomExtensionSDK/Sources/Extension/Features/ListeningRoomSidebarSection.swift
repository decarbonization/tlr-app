/*
 * MIT No Attribution
 *
 * Copyright 2025 Peter "Kevin" Contreras
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

public struct ListeningRoomSidebarSection: ListeningRoomExtensionFeature, Codable, Sendable {
    public init(@ListeningRoomExtensionFeatureBuilder title: () -> some ListeningRoomExtensionFeature,
                @ListeningRoomExtensionFeatureBuilder items: () -> some ListeningRoomExtensionFeature) {
        let textFeatures = title()._collectAll(ListeningRoomExtensionFeatureText.self)
        self._title = textFeatures.reduce("") { acc, next in acc + next._content }
        
        let itemFeatures = items()._collectAll(ListeningRoomExtensionFeatureLink.self)
        self._items = itemFeatures
    }
    
    public init(title: String,
                @ListeningRoomExtensionFeatureBuilder items: () -> some ListeningRoomExtensionFeature) {
        self.init(title: { ListeningRoomExtensionFeatureText(verbatim: title) },
                  items: items)
    }
    
    public let _title: String
    public let _items: [ListeningRoomExtensionFeatureLink]
    
    public var feature: some ListeningRoomExtensionFeature {
        ListeningRoomExtensionTopLevelFeature.sidebarSection(self)
    }
}
