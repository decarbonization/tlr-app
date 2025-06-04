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
import os

@Observable public final class ListeningRoomNotification: Identifiable, Codable, Sendable {
    public struct ID: Hashable, Codable, Sendable {
        public init(bundleID: String,
                    id: String) {
            self.bundleID = bundleID
            self.id = id
        }
        
        public init(_ id: String) {
            guard let bundleID = Bundle.main.bundleIdentifier else {
                fatalError("Main bundle does not have an ID")
            }
            self.init(bundleID: bundleID,
                      id: id)
        }
        
        public static var unique: Self {
            Self(UUID().uuidString)
        }
        
        public var bundleID: String
        public var id: String
    }
    
    public enum Progress: Equatable, Codable, Sendable {
        case indeterminate
        case determinate(totalUnitCount: UInt64, completedUnitCount: UInt64)
        
        public var isIndeterminate: Bool {
            switch self {
            case .indeterminate:
                return true
            case .determinate(_, _):
                return false
            }
        }
        
        public var isFinished: Bool {
            guard case .determinate(let totalUnitCount, let completedUnitCount) = self else {
                return false
            }
            return completedUnitCount == totalUnitCount
        }
        
        public var fractionCompleted: Double {
            guard case .determinate(let totalUnitCount, let completedUnitCount) = self else {
                return 0.0
            }
            return Double(completedUnitCount) / Double(totalUnitCount)
        }
    }
    
    public struct Action: Identifiable, Equatable, Codable, Sendable {
        public enum Role: Hashable, Codable, Sendable {
            case cancel
            case destructive
        }
        
        public init(id: ListeningRoomActionID,
                    title: String,
                    role: Role? = nil) {
            self.id = id
            self.title = title
            self.role = role
        }
        
        public var id: ListeningRoomActionID
        public var title: String
        public var role: Role?
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case storage
    }
    
    private struct Storage: Codable, Sendable {
        var title: String
        var details: String?
        var icon: ListeningRoomImage?
        var progress: Progress?
        var actions: [Action]
    }
    
    public init(id: ID,
                title: String,
                details: String? = nil,
                icon: ListeningRoomImage? = nil,
                progress: Progress? = nil,
                actions: [Action] = []) {
        self.id = id
        self._storage = .init(initialState: Storage(title: title,
                                                    details: details,
                                                    icon: icon,
                                                    progress: progress,
                                                    actions: actions))
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(ID.self, forKey: .id)
        self._storage = .init(initialState: try container.decode(Storage.self, forKey: .storage))
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        let storage = _storage.withLock { $0 }
        try container.encode(storage, forKey: .storage)
    }
    
    public let id: ID
    private let _storage: OSAllocatedUnfairLock<Storage>
    
    private func _access<T: Sendable>(_ property: WritableKeyPath<Storage, T> & Sendable) -> T {
        _storage.withLock { storage in
            storage[keyPath: property]
        }
    }
    
    private func _assign<T: Sendable>(_ newValue: T, to property: WritableKeyPath<Storage, T> & Sendable) {
        _storage.withLock { storage in
            storage[keyPath: property] = newValue
        }
    }
    
    @ObservationTracked public var title: String {
        get {
            _access(\.title)
        }
        set {
            _assign(newValue, to: \.title)
        }
    }
    
    @ObservationTracked public var details: String? {
        get {
            _access(\.details)
        }
        set {
            _assign(newValue, to: \.details)
        }
    }
    
    @ObservationTracked public var icon: ListeningRoomImage? {
        get {
            _access(\.icon)
        }
        set {
            _assign(newValue, to: \.icon)
        }
    }
    
    @ObservationTracked public var progress: Progress? {
        get {
            _access(\.progress)
        }
        set {
            _assign(newValue, to: \.progress)
        }
    }
    
    @ObservationTracked public var actions: [Action] {
        get {
            _access(\.actions)
        }
        set {
            _assign(newValue, to: \.actions)
        }
    }
}

extension ListeningRoomNotification {
    public convenience init(presenting error: any Error,
                            actions: [Action] = []) {
        self.init(id: .unique,
                  title: NSLocalizedString("Error", comment: ""),
                  details: error.localizedDescription,
                  actions: actions)
    }
}
