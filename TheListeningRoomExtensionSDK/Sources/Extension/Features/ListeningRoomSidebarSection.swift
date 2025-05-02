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

public struct ListeningRoomSidebarSection: ListeningRoomFeature, Codable, Sendable {
    public init(@ListeningRoomFeatureBuilder title: () -> some ListeningRoomFeature,
                @ListeningRoomFeatureBuilder items: () -> some ListeningRoomFeature) {
        let textFeatures = title()._collectAll(ListeningRoomFeatureText.self)
        self._title = textFeatures.reduce("") { acc, next in acc + next._content }
        
        let itemFeatures = items()._collectAll(ListeningRoomFeatureLink.self)
        self._items = itemFeatures
    }
    
    public init(title: String,
                @ListeningRoomFeatureBuilder items: () -> some ListeningRoomFeature) {
        self.init(title: { ListeningRoomFeatureText(verbatim: title) },
                  items: items)
    }
    
    public let _title: String
    public let _items: [ListeningRoomFeatureLink]
    
    public var feature: some ListeningRoomFeature {
        ListeningRoomTopLevelFeature.sidebarSection(self)
    }
}
