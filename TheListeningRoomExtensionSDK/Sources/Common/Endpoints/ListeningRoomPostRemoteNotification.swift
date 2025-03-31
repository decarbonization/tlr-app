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

extension Notification.Name {
    public static let ListeningRoomPlayQueueDidChange = Notification.Name("ListeningRoomPlayQueueDidChange")
}

public struct ListeningRoomPostRemoteNotification: ListeningRoomXPCRequest {
    public typealias Response = Nothing
    
    public init(notificationName: Notification.Name) {
        self.notificationName = notificationName.rawValue
    }
    
    private var notificationName: String
    
    public var notification: Notification.Name {
        get {
            Notification.Name(rawValue: notificationName)
        }
        set {
            notificationName = newValue.rawValue
        }
    }
}

extension ListeningRoomXPCRequest where Self == ListeningRoomPostRemoteNotification {
    public static func postRemoteNotification(name: Notification.Name) -> Self {
        Self(notificationName: name)
    }
}

public struct ListeningRoomPostRemoteNotificationEndpoint: ListeningRoomXPCEndpoint {
    public init(object: (Any & Sendable)? = nil) {
        self.object = object
    }
    
    private let object: (Any & Sendable)?
    
    public func callAsFunction(_ request: ListeningRoomPostRemoteNotification) async throws -> Nothing {
        NotificationCenter.default.post(name: request.notification,
                                        object: object)
        return .nothing
    }
}
