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

@MainActor final class PluginServiceMessageHandler<Service: PluginService>: NSObject, WKScriptMessageHandlerWithReply {
    init(_ service: Service) {
        self.service = service
    }
    
    private let service: Service
    
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
            let reply = try await service.receive(message)
            let rawReplyBytes = try Service.replyEncoder.encode(reply)
            let rawReply = String(data: rawReplyBytes, encoding: .utf8)
            return (rawReply, nil)
        } catch {
            return (nil, "\(type(of: error)): \(error.localizedDescription)")
        }
    }
}
