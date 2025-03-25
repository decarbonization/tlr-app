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

import Foundation

@propertyWrapper struct Setting<Value>: CustomDebugStringConvertible {
    private let _defaultValue: Value
    private let _storage: any _SettingStorage<Value>
    
    var wrappedValue: Value {
        get {
            _storage.access() ?? _defaultValue
        }
        nonmutating set {
            _storage.assign(newValue)
        }
    }
    
    func reset() {
        _storage.assign(nil)
    }
    
    var debugDescription: String {
        "Setting(wrappedValue: \(wrappedValue))"
    }
}

extension Setting: Equatable where Value: Equatable {
    static func == (lhs: Setting<Value>, rhs: Setting<Value>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension Setting: Hashable where Value: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

extension Setting: Sendable where Value: Sendable {
}

// MARK: -

extension Setting {
    init(wrappedValue: Value, _ key: String, storage: UserDefaults = .standard) where Value: Codable {
        _defaultValue = wrappedValue
        _storage = _CodableSettingStorage(key: key, userDefaults: storage)
    }
    
    init(wrappedValue: Value = nil, _ key: String, storage: UserDefaults = .standard) where Value: Codable & ExpressibleByNilLiteral {
        _defaultValue = nil
        _storage = _CodableSettingStorage(key: key, userDefaults: storage)
    }
}

// MARK: -

extension Setting {
    // NOTE: Add more primitives here as needed
    
    init(wrappedValue: Bool, _ key: String, storage: UserDefaults = .standard) where Value == Bool {
        _defaultValue = wrappedValue
        _storage = _PrimitiveSettingStorage(key: key, userDefaults: storage)
    }
    
    init(wrappedValue: Bool? = nil, _ key: String, storage: UserDefaults = .standard) where Value == Bool? {
        _defaultValue = wrappedValue
        _storage = _PrimitiveSettingStorage(key: key, userDefaults: storage)
    }
    
    init(wrappedValue: Double, _ key: String, storage: UserDefaults = .standard) where Value == Double {
        _defaultValue = wrappedValue
        _storage = _PrimitiveSettingStorage(key: key, userDefaults: storage)
    }
    
    init(wrappedValue: Double? = nil, _ key: String, storage: UserDefaults = .standard) where Value == Double? {
        _defaultValue = wrappedValue
        _storage = _PrimitiveSettingStorage(key: key, userDefaults: storage)
    }
    
    init(wrappedValue: Int, _ key: String, storage: UserDefaults = .standard) where Value == Int {
        _defaultValue = wrappedValue
        _storage = _PrimitiveSettingStorage(key: key, userDefaults: storage)
    }
    
    init(wrappedValue: Int? = nil, _ key: String, storage: UserDefaults = .standard) where Value == Int? {
        _defaultValue = wrappedValue
        _storage = _PrimitiveSettingStorage(key: key, userDefaults: storage)
    }
    
    init(wrappedValue: String, _ key: String, storage: UserDefaults = .standard) where Value == String {
        _defaultValue = wrappedValue
        _storage = _PrimitiveSettingStorage(key: key, userDefaults: storage)
    }
    
    init(wrappedValue: String? = nil, _ key: String, storage: UserDefaults = .standard) where Value == String? {
        _defaultValue = wrappedValue
        _storage = _PrimitiveSettingStorage(key: key, userDefaults: storage)
    }
}

// MARK: -

private protocol _SettingStorage<Value>: Sendable {
    associatedtype Value
    
    func access() -> Value?
    func assign(_ newValue: Value?) -> Void
}

private struct _PrimitiveSettingStorage<Value>: _SettingStorage, @unchecked Sendable {
    init(key: String, userDefaults: UserDefaults) {
        self.key = key
        self.userDefaults = userDefaults
    }
    
    private let key: String
    private let userDefaults: UserDefaults
    
    func access() -> Value? {
        userDefaults.object(forKey: key) as? Value
    }
    
    func assign(_ newValue: Value?) {
        if let newValue {
            userDefaults.set(newValue, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
}

private struct _CodableSettingStorage<Value: Codable>: _SettingStorage, @unchecked Sendable {
    init(key: String, userDefaults: UserDefaults) {
        self.key = key
        self.userDefaults = userDefaults
    }
    
    private let key: String
    private let userDefaults: UserDefaults
    
    func access() -> Value? {
        guard let valueData = userDefaults.data(forKey: key) else {
            return nil
        }
        let valueDecoder = PropertyListDecoder()
        do {
            return try valueDecoder.decode(Value.self, from: valueData)
        } catch {
            return nil
        }
    }
    
    func assign(_ newValue: Value?) {
        if let newValue {
            do {
                let valueEncoder = PropertyListEncoder()
                valueEncoder.outputFormat = .binary
                let valueData = try valueEncoder.encode(newValue)
                userDefaults.set(valueData, forKey: key)
            } catch {
                userDefaults.removeObject(forKey: key)
            }
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
}
