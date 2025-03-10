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

import AppKit
import os
import SwiftUI
import WebKit

struct WebExtensionView: View {
    nonisolated static let logger = Logger(subsystem: "io.github.decarbonization.M9r", category: "WebExtensionView")
    
    enum Role {
        case actionPopup
    }
    
    let webExtension: WebExtension
    let role: Role
    @State private var resources: Result<([WKUserScript], [WKContentRuleList]), any Error>?
    @Environment(PlayQueue.self) private var playQueue
    
    var body: some View {
        Group {
            switch resources {
            case nil:
                VStack {
                    ProgressView()
                }
            case .success((let scripts, let rules)):
                _WebExtensionContent(webExtension: webExtension,
                                     role: role,
                                     scripts: scripts,
                                     rules: rules,
                                     services: [PlayQueueService(playQueue: playQueue)])
            case .failure(let error):
                VStack {
                    Text(verbatim: error.localizedDescription)
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task {
            guard resources == nil else {
                return
            }
            do {
                var scripts = [WKUserScript]()
                scripts.append(try await WebExtensionResources.preflightUserScript)
                
                var rules = [WKContentRuleList]()
                rules.append(try await WebExtensionResources.filterFilesRuleList)
                if webExtension.manifest.permissions?.contains(.networking) != true {
                    rules.append(try await WebExtensionResources.filterNetworkingRuleList)
                }
                
                resources = .success((scripts, rules))
            } catch {
                resources = .failure(error)
            }
        }
    }
}

// MARK: -

private struct _WebExtensionContent: NSViewRepresentable {
    let webExtension: WebExtension
    let role: WebExtensionView.Role
    let scripts: [WKUserScript]
    let rules: [WKContentRuleList]
    let services: [any WebExtensionService]
    
    final class EventSink: WebExtensionServiceEventSink {
        let _webView = OSAllocatedUnfairLock<Weak<WKWebView>?>(initialState: nil)
        var webView: WKWebView? {
            get {
                _webView.withLock { $0?.unwrap }
            }
            set {
                _webView.withLock { webView in
                    if let newValue {
                        webView = Weak(wrapping: newValue)
                    } else {
                        webView = nil
                    }
                }
            }
        }
        
        func dispatchEvent(of type: String, with detail: some Encodable) async {
            do {
                let rawDetailData = try WebExtensionResources.jsonEncoder.encode(detail)
                let rawDetail = String(data: rawDetailData, encoding: .utf8)!
                let result = try await webView?.callAsyncJavaScript("player.__dispatchEvent(type, detail)",
                                                                    arguments: ["type": type,
                                                                                "detail": rawDetail],
                                                                    contentWorld: .page)
                WebExtensionView.logger.debug("Dispatched web extension event \(type) with \(String(describing: detail)), got \(String(describing: result)) back")
            } catch {
                WebExtensionView.logger.error("*** Failed to dispatch web extension event \(type) with \(String(describing: detail)), reason \(String(describing: error))")
            }
        }
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        init(webExtension: WebExtension) {
            self.webExtension = webExtension
            self.eventSink = EventSink()
            self.eventPublishers = []
        }
        
        let webExtension: WebExtension
        let eventSink: EventSink
        var eventPublishers: [any WebExtensionEventPublisher]
        
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: any Error) {
            WebExtensionView.logger.error("*** Web view did fail provisional navigation \(String(describing: navigation)), reason: \(error)")
        }
        
        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: any Error) {
            WebExtensionView.logger.error("*** Web view did fail navigation \(String(describing: navigation)), reason: \(error)")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(webExtension: webExtension)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore(forIdentifier: webExtension.persistentID)
        configuration.processPool = WKProcessPool()
        for script in scripts {
            configuration.userContentController.addUserScript(script)
        }
        for rule in rules {
            configuration.userContentController.add(rule)
        }
        configuration.setURLSchemeHandler(WebExtensionURLSchemeHandler(webExtension), forURLScheme: "webex")
        
        let permissions = webExtension.manifest.permissions ?? []
        for service in services {
            func addService<Service: WebExtensionService>(_ service: Service) {
                guard Service.requiredPermissions.isSuperset(of: permissions) else {
                    WebExtensionView.logger.debug("Skipping service \(Service.name) for web extension \(self.webExtension.manifest.name)")
                    return
                }
                let handler = WebExtensionServiceMessageHandler(service, for: webExtension)
                configuration.userContentController.addScriptMessageHandler(handler,
                                                                                  contentWorld: .page,
                                                                                  name: Service.name)
                
                let publisher = service.beginDispatchingEvents(into: context.coordinator.eventSink)
                context.coordinator.eventPublishers.append(publisher)
            }
            addService(service)
        }
        
        let wkWebView = WKWebView(frame: .zero, configuration: configuration)
        wkWebView.navigationDelegate = context.coordinator
        wkWebView.uiDelegate = context.coordinator
        if wkWebView.responds(to: NSSelectorFromString("_setDrawsBackground:")) {
            wkWebView.setValue(false, forKey: "drawsBackground")
        } else {
            WebExtensionView.logger.warning("*** -[WKWebView _setDrawsBackground:] removed, web extension appearance will be incorrect")
        }
        wkWebView.underPageBackgroundColor = .clear
        context.coordinator.eventSink.webView = wkWebView
        
        if let action = webExtension.manifest.action {
            let popupURL = URL(string: action.defaultPopup,
                               relativeTo: URL(string: "webex://")!)
            wkWebView.load(URLRequest(url: popupURL!))
        } else {
            WebExtensionView.logger.error("*** Web extension does not have action")
        }
        
        return wkWebView
    }
    
    func updateNSView(_ wkWebView: WKWebView, context: Context) {
    }
    
    static func dismantleNSView(_ wkWebView: WKWebView, coordinator: Coordinator) {
        coordinator.eventSink.webView = nil
        for eventPublisher in coordinator.eventPublishers {
            eventPublisher.stop()
        }
        coordinator.eventPublishers.removeAll()
    }
}
