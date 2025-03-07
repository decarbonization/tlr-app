/*
 * M9r
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

import SwiftData
import SwiftUI

struct ItemRatingMenu: View {
    init(selection: Set<PersistentIdentifier>) {
        self.selection = selection
    }
    
    private let selection: Set<PersistentIdentifier>
    @Environment(\.modelContext) private var modelContext
    @AppStorage("RatingStyle") private var ratingStyle = RatingStyle.default
    
    var body: some View {
        Menu("Rating") {
            switch ratingStyle {
            case .binary:
                Button("Like", systemImage: "hand.thumbsup") {
                    updateRatings(to: 5)
                }
                Button("Dislike", systemImage: "hand.thumbsdown") {
                    updateRatings(to: 1)
                }
            case .stars:
                ForEach(0 ..< 5) { index in
                    let rating = Float(index + 1)
                    Button(String(repeating: "􀋃", count: Int(rating)) + String(repeating: "􀋂", count: 5 - Int(rating))) {
                        updateRatings(to: rating)
                    }
                    .accessibilityLabel("\(rating) Stars")
                }
            }
        }
    }
    
    private func updateRatings(to newRating: Float?) {
        for itemID in selection {
            guard let collection = modelContext.model(for: itemID) as? SongCollection else {
                continue
            }
            for song in collection.sortedSongs {
                song.rating = newRating
            }
        }
    }
}
