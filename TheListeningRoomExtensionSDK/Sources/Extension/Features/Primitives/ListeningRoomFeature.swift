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

public protocol ListeningRoomFeature {
    associatedtype Feature: ListeningRoomFeature
    
    var feature: Feature { get }
    
    func _visit(_ visitor: inout some _ListeningRoomExtensionVisitor) -> Void
}

extension ListeningRoomFeature {
    public func _visit(_ visitor: inout some _ListeningRoomExtensionVisitor) {
        visitor._visit(feature)
    }
}

public protocol _ListeningRoomExtensionVisitor {
    mutating func _visit<Feature: ListeningRoomFeature>(_ feature: Feature) -> Void
}

extension Never: ListeningRoomFeature {
    public var feature: Never {
        fatalError()
    }
}

extension Optional: ListeningRoomFeature where Wrapped: ListeningRoomFeature {
    public var feature: some ListeningRoomFeature {
        self
    }
    
    public func _visit(_ visitor: inout some _ListeningRoomExtensionVisitor) {
        if let feature = self {
            visitor._visit(feature)
        }
    }
}

extension ListeningRoomFeature {
    internal func _collectAll<Feature: ListeningRoomFeature>(_ featureType: Feature.Type) -> [Feature] {
        var visitor = _CollectAllVisitor(featureType)
        _visit(&visitor)
        return visitor.results
    }
}

private struct _CollectAllVisitor<Feature: ListeningRoomFeature>: _ListeningRoomExtensionVisitor {
    init(_ featureType: Feature.Type = Feature.self) {
        results = []
    }
    
    var results: [Feature]
    
    mutating func _visit(_ feature: some ListeningRoomFeature) {
        if let result = feature as? Feature {
            results.append(result)
        }
    }
}
