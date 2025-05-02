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

import SwiftData
import SwiftUI

extension View {
    func revealInLibrary(action: @escaping @MainActor (Set<PersistentIdentifier>) -> Void) -> some View {
        transformPreference(_RevealInLibraryActionsKey.self) { actions in
            actions.append(_RevealInLibraryAction(action))
        }
    }
    
    func libraryRevealable() -> some View {
        modifier(_LibraryRevealableViewModifier())
    }
}

extension EnvironmentValues {
    @Entry fileprivate(set) var revealInLibrary: @MainActor (Set<PersistentIdentifier>) -> Void = { _ in }
}

private struct _LibraryRevealableViewModifier: ViewModifier {
    @State private var actions = [_RevealInLibraryAction]()
    
    func body(content: Content) -> some View {
        content
            .onPreferenceChange(_RevealInLibraryActionsKey.self) { newValue in
                actions = newValue
            }
            .environment(\.revealInLibrary) { itemIDs in
                for action in actions {
                    action(itemIDs)
                }
            }
    }
}

private final class _RevealInLibraryAction: Equatable {
    init(_ body: @escaping @MainActor (Set<PersistentIdentifier>) -> Void) {
        self.body = body
    }
    
    private let body: @MainActor (Set<PersistentIdentifier>) -> Void
    
    @MainActor func callAsFunction(_ itemIDs: Set<PersistentIdentifier>) {
        body(itemIDs)
    }
    
    static func == (lhs: _RevealInLibraryAction, rhs: _RevealInLibraryAction) -> Bool {
        lhs === rhs
    }
}

private enum _RevealInLibraryActionsKey: PreferenceKey {
    static var defaultValue: [_RevealInLibraryAction] {
        []
    }
    
    static func reduce(value: inout [_RevealInLibraryAction], nextValue: () -> [_RevealInLibraryAction]) {
        value.append(contentsOf: nextValue())
    }
}
