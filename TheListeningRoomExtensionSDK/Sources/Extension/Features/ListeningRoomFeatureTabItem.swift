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

public struct ListeningRoomFeatureTabItem: ListeningRoomFeature, Codable, Sendable {
    public enum Position: String, Codable, Sendable {
        case primary
        case secondary
    }
    
    public init(position: Position,
                sceneID: String,
                @ListeningRoomFeatureBuilder title: () -> some ListeningRoomFeature,
                @ListeningRoomFeatureBuilder image: () -> some ListeningRoomFeature) {
        self._position = position
        self._sceneID = sceneID
        
        let titleFeatures = title()._collectAll(ListeningRoomFeatureText.self)
        self._title = titleFeatures.reduce("") { acc, next in acc + next._content }
        
        let imageFeatures = image()._collectAll(ListeningRoomImage.self)
        self._icon = imageFeatures.first
    }
    
    public init(position: Position,
                sceneID: String,
                title: String,
                systemImage: String) {
        self.init(position: position,
                  sceneID: sceneID,
                  title: { ListeningRoomFeatureText(verbatim: title) },
                  image: { ListeningRoomImage.systemImage(systemImage) })
    }
    
    public init(position: Position,
                sceneID: String,
                title: String) {
        self.init(position: position,
                  sceneID: sceneID,
                  title: { ListeningRoomFeatureText(verbatim: title) },
                  image: { })
    }
    
    public var _position: Position
    public var _sceneID: String
    public var _title: String
    public var _icon: ListeningRoomImage?
    
    public var feature: some ListeningRoomFeature {
        ListeningRoomTopLevelFeature.tabItem(self)
    }
}
