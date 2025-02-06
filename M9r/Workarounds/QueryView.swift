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

/// Encapsulates a SwiftData query which can be changed based on a passed in fetch descriptor.
///
/// Works around `@Query` not projecting its fetch descriptor making it impossible to change sort order, etc.
struct QueryView<Model: PersistentModel, Content: View>: View {
    init(fetchDescriptor: Binding<FetchDescriptor<Model>>,
         transaction: Transaction? = nil,
         @ViewBuilder content: @escaping ([Model]) -> Content) {
        self._fetchDescriptor = fetchDescriptor
        self.content = content
        self._results = .init(fetchDescriptor.wrappedValue, transaction: transaction)
    }
    
    @Binding private var fetchDescriptor: FetchDescriptor<Model>
    @ViewBuilder private let content: ([Model]) -> Content
    @Query private var results: [Model]
    
    var body: some View {
        content(results)
    }
}
