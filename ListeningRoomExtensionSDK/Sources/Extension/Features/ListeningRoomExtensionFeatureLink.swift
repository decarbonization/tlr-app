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

public struct ListeningRoomExtensionFeatureLink: ListeningRoomExtensionFeature, Codable, Sendable {
    public init(sceneID: String,
                @ListeningRoomExtensionFeatureBuilder title: () -> some ListeningRoomExtensionFeature,
                @ListeningRoomExtensionFeatureBuilder image: () -> some ListeningRoomExtensionFeature) {
        self._sceneID = sceneID
        
        let titleFeatures = title()._collectAll(ListeningRoomExtensionFeatureText.self)
        self._title = titleFeatures.reduce("") { acc, next in acc + next._content }
        
        let imageFeatures = image()._collectAll(ListeningRoomExtensionFeatureImage.self)
        self._image = imageFeatures.first?._representation
    }
    
    public init(sceneID: String,
                title: String,
                systemImage: String) {
        self.init(sceneID: sceneID,
                  title: { ListeningRoomExtensionFeatureText(verbatim: title) },
                  image: { ListeningRoomExtensionFeatureImage(systemImage: systemImage) })
    }
    
    public init(sceneID: String,
                title: String) {
        self.init(sceneID: sceneID,
                  title: { ListeningRoomExtensionFeatureText(verbatim: title) },
                  image: { })
    }
    
    public var _sceneID: String
    public var _title: String
    public var _image: ListeningRoomExtensionFeatureImage._Representation?
    
    public var feature: some ListeningRoomExtensionFeature {
        self
    }
}
