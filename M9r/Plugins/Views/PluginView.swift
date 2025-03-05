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

struct PluginView: View {
    nonisolated static let logger = Logger(subsystem: "io.github.decarbonization.M9r", category: "PluginView")
    
    enum Role {
        case actionPopup
    }
    
    let plugin: Plugin
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
                _PluginContent(plugin: plugin,
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
                scripts.append(try await PluginResources.preflightUserScript)
                
                var rules = [WKContentRuleList]()
                rules.append(try await PluginResources.filterFilesRuleList)
                if plugin.manifest.permissions?.contains(.networking) != true {
                    rules.append(try await PluginResources.filterNetworkingRuleList)
                }
                
                resources = .success((scripts, rules))
            } catch {
                resources = .failure(error)
            }
        }
    }
}

// MARK: -

private struct _PluginContent: NSViewRepresentable {
    let plugin: Plugin
    let role: PluginView.Role
    let scripts: [WKUserScript]
    let rules: [WKContentRuleList]
    let services: [any PluginService]
    
    final class EventSink: PluginEventSink {
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
                let rawDetailData = try PluginResources.jsonEncoder.encode(detail)
                let rawDetail = String(data: rawDetailData, encoding: .utf8)!
                let result = try await webView?.callAsyncJavaScript("player.__dispatchEvent(type, detail)",
                                                                    arguments: ["type": type,
                                                                                "detail": rawDetail],
                                                                    contentWorld: .page)
                PluginView.logger.debug("Dispatched plugin event \(type) with \(String(describing: detail)), got \(String(describing: result)) back")
            } catch {
                PluginView.logger.error("*** Failed to dispatch plugin event \(type) with \(String(describing: detail)), reason \(String(describing: error))")
            }
        }
    }
    
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        init(plugin: Plugin) {
            self.plugin = plugin
            self.eventSink = EventSink()
            self.eventPublishers = []
        }
        
        let plugin: Plugin
        let eventSink: EventSink
        var eventPublishers: [any PluginEventSinkPublisher]
        
        func webView(_ webView: WKWebView,
                     didFailProvisionalNavigation navigation: WKNavigation!,
                     withError error: any Error) {
            PluginView.logger.error("*** Web view did fail provisional navigation \(String(describing: navigation)), reason: \(error)")
        }
        
        func webView(_ webView: WKWebView,
                     didFail navigation: WKNavigation!,
                     withError error: any Error) {
            PluginView.logger.error("*** Web view did fail navigation \(String(describing: navigation)), reason: \(error)")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(plugin: plugin)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let pluginConfiguration = WKWebViewConfiguration()
        pluginConfiguration.websiteDataStore = WKWebsiteDataStore(forIdentifier: plugin.persistentID)
        pluginConfiguration.processPool = WKProcessPool()
        for script in scripts {
            pluginConfiguration.userContentController.addUserScript(script)
        }
        for rule in rules {
            pluginConfiguration.userContentController.add(rule)
        }
        pluginConfiguration.setURLSchemeHandler(PluginURLSchemeHandler(plugin), forURLScheme: "plugin")
        
        let pluginPermissions = plugin.manifest.permissions ?? []
        for service in services {
            func addService<Service: PluginService>(_ service: Service) {
                guard Service.requiredPermissions.isSuperset(of: pluginPermissions) else {
                    PluginView.logger.debug("Skipping service \(Service.name) for plugin \(self.plugin.manifest.name)")
                    return
                }
                let handler = PluginServiceMessageHandler(service, for: plugin)
                pluginConfiguration.userContentController.addScriptMessageHandler(handler,
                                                                                  contentWorld: .page,
                                                                                  name: Service.name)
                
                let publisher = service.beginDispatchingEvents(into: context.coordinator.eventSink)
                context.coordinator.eventPublishers.append(publisher)
            }
            addService(service)
        }
        
        let wkWebView = WKWebView(frame: .zero, configuration: pluginConfiguration)
        wkWebView.navigationDelegate = context.coordinator
        wkWebView.uiDelegate = context.coordinator
        if wkWebView.responds(to: NSSelectorFromString("_setDrawsBackground:")) {
            wkWebView.setValue(false, forKey: "drawsBackground")
        } else {
            PluginView.logger.warning("*** -[WKWebView _setDrawsBackground:] removed, plugin appearance will be incorrect")
        }
        wkWebView.underPageBackgroundColor = .clear
        context.coordinator.eventSink.webView = wkWebView
        
        if let action = plugin.manifest.action {
            let popupURL = URL(string: action.defaultPopup,
                               relativeTo: URL(string: "plugin://")!)
            wkWebView.load(URLRequest(url: popupURL!))
        } else {
            PluginView.logger.error("*** Plugin does not have action")
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
