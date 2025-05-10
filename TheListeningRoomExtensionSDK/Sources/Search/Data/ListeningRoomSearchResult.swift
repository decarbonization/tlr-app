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

public struct ListeningRoomSearchResult: Identifiable, Codable, Sendable {
    public init(id: ListeningRoomID,
                itemIDs: some Sequence<ListeningRoomID>,
                artwork: ListeningRoomImage? = nil,
                primaryTitle: String? = nil,
                secondaryTitle: String? = nil,
                tertiaryTitle: String? = nil) {
        self.id = id
        self.itemIDs = [ListeningRoomID](itemIDs)
        self.artwork = artwork
        self.primaryTitle = primaryTitle
        self.secondaryTitle = secondaryTitle
        self.tertiaryTitle = tertiaryTitle
    }
    
    public let id: ListeningRoomID
    public var itemIDs: [ListeningRoomID]
    public var artwork: ListeningRoomImage?
    public var primaryTitle: String?
    public var secondaryTitle: String?
    public var tertiaryTitle: String?
}
