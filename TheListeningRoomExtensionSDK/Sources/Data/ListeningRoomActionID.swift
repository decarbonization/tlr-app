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

/// A value which uniquely identifies a named action.
public struct ListeningRoomActionID: Hashable, Codable, Sendable {
    /// Create an action identifier value.
    ///
    /// - parameter bundleID: The identifier of the bundle which encapsulates the action's logic.
    /// - parameter name: The name of the action. E.g. `"importFiles"`.
    public init(bundleID: String,
                name: String) {
        self.bundleID = bundleID
        self.name = name
    }
    
    /// Create an action identifier value for an action whose logic is encapsulated by the current main bundle.
    ///
    /// - parameter name: The name of the action. E.g. `"importFiles"`.
    public init(_ name: String) {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            fatalError("Main bundle does not have an ID")
        }
        self.init(bundleID: bundleID,
                  name: name)
    }
    
    /// The identifier of the bundle which encapsulates the action's logic.
    public var bundleID: String
    
    /// The name of the action. E.g. `"importFiles"`.
    public var name: String
}
