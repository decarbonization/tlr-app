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

import SwiftUI
import WebKit

struct PluginActionContent: NSViewRepresentable {
    let plugin: Plugin
    
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        init(plugin: Plugin) {
            self.plugin = plugin
        }
        
        var plugin: Plugin
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(plugin: plugin)
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let pluginConfiguration = WKWebViewConfiguration()
        pluginConfiguration.websiteDataStore = WKWebsiteDataStore(forIdentifier: plugin.persistentID)
        pluginConfiguration.processPool = WKProcessPool()
        if let preflightURL = Bundle.main.url(forResource: "Preflight", withExtension: "js"),
           let preflightSource = try? String(contentsOf: preflightURL, encoding: .utf8) {
            pluginConfiguration.userContentController.addUserScript(WKUserScript(source: preflightSource,
                                                                                 injectionTime: .atDocumentStart,
                                                                                 forMainFrameOnly: true))
        }
        pluginConfiguration.setURLSchemeHandler(PluginURLSchemeHandler(plugin: plugin), forURLScheme: "plugin")
        let wkWebView = WKWebView(frame: .zero, configuration: pluginConfiguration)
        wkWebView.navigationDelegate = context.coordinator
        wkWebView.uiDelegate = context.coordinator
        wkWebView.setValue(false, forKey: "drawsBackground")
        wkWebView.underPageBackgroundColor = .clear
        return wkWebView
    }
    
    func updateNSView(_ wkWebView: WKWebView, context: Context) {
        context.coordinator.plugin = plugin
        do {
            guard let action = plugin.manifest.action else {
                throw PluginError.missingRequiredConfiguration("manifest.action")
            }
            let popupURL = try plugin.resourceURL(action.defaultPopup)
            wkWebView.load(URLRequest(url: popupURL))
        } catch {
            // TODO: show error page
        }
    }
}
