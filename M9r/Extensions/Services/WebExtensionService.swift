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

enum WebExtensionServiceError: Error {
    case framePermissionDenied
    case unexpectedName
    case badBody
    case malformedMessage
}

struct WebExtensionServiceContext: Sendable {
    let manifest: WebExtension.Manifest
}

protocol WebExtensionService: Sendable {
    associatedtype Message: Decodable
    associatedtype Reply: Encodable
    
    static var name: String { get }
    static var requiredPermissions: Set<WebExtension.Permission> { get }
    
    func beginDispatchingEvents(into eventSink: any WebExtensionServiceEventSink) -> any WebExtensionEventPublisher
    func receive(_ message: Message, with context: WebExtensionServiceContext) async throws -> Reply
}

protocol WebExtensionServiceEventSink: AnyObject, Sendable {
    func dispatchEvent(of type: String, with detail: some Encodable) async -> Void
}

protocol WebExtensionEventPublisher: AnyObject, Sendable {
    func stop() -> Void
}

@MainActor final class WebExtensionServiceMessageHandler<Service: WebExtensionService>: NSObject, WKScriptMessageHandlerWithReply {
    init(_ service: Service,
         for webExtension: WebExtension) {
        self.service = service
        self.webExtension = webExtension
    }
    
    private let service: Service
    private let webExtension: WebExtension
    
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) async -> (Any?, String?) {
        do {
            guard message.frameInfo.isMainFrame else {
                throw WebExtensionServiceError.framePermissionDenied
            }
            guard message.name == Service.name else {
                throw WebExtensionServiceError.unexpectedName
            }
            guard let rawMessage = message.body as? String else {
                throw WebExtensionServiceError.badBody
            }
            guard let rawMessageBytes = rawMessage.data(using: .utf8) else {
                throw WebExtensionServiceError.malformedMessage
            }
            let message = try WebExtensionResources.jsonDecoder.decode(Service.Message.self, from: rawMessageBytes)
            let context = WebExtensionServiceContext(manifest: webExtension.manifest)
            let reply = try await service.receive(message, with: context)
            let rawReplyBytes = try WebExtensionResources.jsonEncoder.encode(reply)
            let rawReply = String(data: rawReplyBytes, encoding: .utf8)
            return (rawReply, nil)
        } catch {
            return (nil, "\(type(of: error)): \(error.localizedDescription)")
        }
    }
}
