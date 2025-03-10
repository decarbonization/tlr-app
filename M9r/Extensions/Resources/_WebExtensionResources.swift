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

enum WebExtensionResources {
    @MainActor static var preflightUserScript: WKUserScript {
        get async throws {
            guard let preflightURL = Bundle.main.url(forResource: "Preflight", withExtension: "js") else {
                throw CocoaError(.fileNoSuchFile)
            }
            let preflightSource = try String(contentsOf: preflightURL, encoding: .utf8)
            return WKUserScript(source: preflightSource,
                                injectionTime: .atDocumentStart,
                                forMainFrameOnly: true)
        }
    }
    
    @MainActor static var filterFilesRuleList: WKContentRuleList! {
        get async throws {
            guard let filterFilesURL = Bundle.main.url(forResource: "FilterFiles", withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile, userInfo: [
                    NSLocalizedDescriptionKey: "FilterFiles rule list missing",
                ])
            }
            let filterFilesSource = try String(contentsOf: filterFilesURL, encoding: .utf8)
            return try await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "FilterFiles",
                                                                                     encodedContentRuleList: filterFilesSource)
        }
    }
    
    @MainActor static var filterNetworkingRuleList: WKContentRuleList! {
        get async throws {
            guard let filterFilesURL = Bundle.main.url(forResource: "FilterNetworking", withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile, userInfo: [
                    NSLocalizedDescriptionKey: "FilterNetworking rule list missing",
                ])
            }
            let filterFilesSource = try String(contentsOf: filterFilesURL, encoding: .utf8)
            return try await WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "FilterNetworking",
                                                                                     encodedContentRuleList: filterFilesSource)
        }
    }
    
    static var jsonDecoder: JSONDecoder {
        let messageDecoder = JSONDecoder()
        messageDecoder.keyDecodingStrategy = .useDefaultKeys
        messageDecoder.dataDecodingStrategy = .base64
        messageDecoder.dateDecodingStrategy = .iso8601
        return messageDecoder
    }
    
    static var jsonEncoder: JSONEncoder {
        let replyEncoder = JSONEncoder()
        replyEncoder.keyEncodingStrategy = .useDefaultKeys
        replyEncoder.dataEncodingStrategy = .base64
        replyEncoder.dateEncodingStrategy = .iso8601
        return replyEncoder
    }
}
