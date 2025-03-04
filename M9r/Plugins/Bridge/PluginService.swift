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

import Foundation

enum PluginServiceError: Error {
    case framePermissionDenied
    case unexpectedName
    case badBody
    case malformedMessage
}

protocol PluginService: Sendable {
    associatedtype Message: Decodable
    associatedtype Reply: Encodable
    
    static var name: String { get }
    static var requiredPermissions: Set<Plugin.Permission> { get }
    static var messageDecoder: JSONDecoder { get }
    static var replyEncoder: JSONEncoder { get }
    
    func receive(_ message: Message) async throws -> Reply
}

extension PluginService {
    static var messageDecoder: JSONDecoder {
        let messageDecoder = JSONDecoder()
        messageDecoder.keyDecodingStrategy = .convertFromSnakeCase
        messageDecoder.dataDecodingStrategy = .base64
        messageDecoder.dateDecodingStrategy = .iso8601
        return messageDecoder
    }
    
    static var replyEncoder: JSONEncoder {
        let replyEncoder = JSONEncoder()
        replyEncoder.keyEncodingStrategy = .convertToSnakeCase
        replyEncoder.dataEncodingStrategy = .base64
        replyEncoder.dateEncodingStrategy = .iso8601
        return replyEncoder
    }
}
