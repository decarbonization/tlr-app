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
import WebKit

enum PluginServiceError: Error {
    case framePermissionDenied
    case unexpectedName
    case badBody
    case malformedMessage
}

struct PluginServiceContext: Sendable {
    let manifest: Plugin.Manifest
}

protocol PluginService: Sendable {
    associatedtype Message: Decodable
    associatedtype Reply: Encodable
    
    static var name: String { get }
    static var requiredPermissions: Set<Plugin.Permission> { get }
    static var messageDecoder: JSONDecoder { get }
    static var replyEncoder: JSONEncoder { get }
    
    func beginDispatchingEvents(into eventSink: any PluginEventSink) -> any PluginEventSinkPublisher
    func receive(_ message: Message, with context: PluginServiceContext) async throws -> Reply
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

protocol PluginEventSink: AnyObject, Sendable {
    func dispatchEvent(of type: String, with detail: some Encodable) async throws -> Void
}

protocol PluginEventSinkPublisher: AnyObject, Sendable {
    func stop() -> Void
}

@MainActor final class PluginServiceMessageHandler<Service: PluginService>: NSObject, WKScriptMessageHandlerWithReply {
    init(_ service: Service,
         for plugin: Plugin) {
        self.service = service
        self.plugin = plugin
    }
    
    private let service: Service
    private let plugin: Plugin
    
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) async -> (Any?, String?) {
        do {
            guard message.frameInfo.isMainFrame else {
                throw PluginServiceError.framePermissionDenied
            }
            guard message.name == Service.name else {
                throw PluginServiceError.unexpectedName
            }
            guard let rawMessage = message.body as? String else {
                throw PluginServiceError.badBody
            }
            guard let rawMessageBytes = rawMessage.data(using: .utf8) else {
                throw PluginServiceError.malformedMessage
            }
            let message = try Service.messageDecoder.decode(Service.Message.self, from: rawMessageBytes)
            let context = PluginServiceContext(manifest: plugin.manifest)
            let reply = try await service.receive(message, with: context)
            let rawReplyBytes = try Service.replyEncoder.encode(reply)
            let rawReply = String(data: rawReplyBytes, encoding: .utf8)
            return (rawReply, nil)
        } catch {
            return (nil, "\(type(of: error)): \(error.localizedDescription)")
        }
    }
}
