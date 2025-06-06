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

@resultBuilder public enum ListeningRoomFeatureBuilder {
    public static func buildBlock() -> some ListeningRoomFeature {
        _EmptyFeature()
    }
    
    public static func buildBlock<each F: ListeningRoomFeature>(_ content: repeat (each F)) -> some ListeningRoomFeature {
        _FeatureGroup(repeat (each content))
    }
    
    public static func buildEither<TrueContent: ListeningRoomFeature, FalseContent: ListeningRoomFeature>(first content: TrueContent) -> some ListeningRoomFeature {
        _ConditionalFeature<TrueContent, FalseContent>.trueContent(content)
    }
    
    public static func buildEither<TrueContent: ListeningRoomFeature, FalseContent: ListeningRoomFeature>(first content: FalseContent) -> some ListeningRoomFeature {
        _ConditionalFeature<TrueContent, FalseContent>.falseContent(content)
    }
    
    public static func buildIf(_ content: (some ListeningRoomFeature)?) -> (some ListeningRoomFeature)? {
        content
    }
}
