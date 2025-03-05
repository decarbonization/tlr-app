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

final class PluginContentView: NSView, WKNavigationDelegate, WKUIDelegate {
    private static let logger = Logger(subsystem: "io.github.decarbonization.M9r", category: "PluginContent")
    
    enum Role {
        case action
    }
    
    init(plugin: Plugin,
         role: Role,
         frame frameRect: NSRect = .zero) {
        self.plugin = plugin
        self.role = role
        self.errorLabel = NSTextField(wrappingLabelWithString: "")
        
        super.init(frame: frameRect)
        
        errorLabel.font = NSFont.preferredFont(forTextStyle: .largeTitle)
        errorLabel.textColor = .secondaryLabelColor
        errorLabel.alignment = .center
        errorLabel.isHidden = true
        addSubview(errorLabel)
        
        withObservationTracking {
            withExtendedLifetime(plugin.manifest) {
                // do nothing.
            }
        } onChange: { [weak self] in
            Task {
                await self?.recreateWebView()
            }
        }

        Task {
            await recreateWebView()
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @available(*, unavailable)
    override func encode(with coder: NSCoder) {
        fatalError("encode(with:) has not been implemented")
    }
    
    let plugin: Plugin
    let role: Role
    
    private let errorLabel: NSTextField
    private var error: (any Error)? {
        didSet {
            if let error {
                errorLabel.stringValue = error.localizedDescription
                errorLabel.isHidden = false
            } else {
                errorLabel.stringValue = ""
                errorLabel.isHidden = true
            }
            needsLayout = true
            invalidateIntrinsicContentSize()
        }
    }
    private var webView: WKWebView? {
        willSet {
            webView?.removeFromSuperview()
        }
        didSet {
            if let webView {
                addSubview(webView)
            }
            needsLayout = true
            invalidateIntrinsicContentSize()
        }
    }
    
    private func recreateWebView() async {
        do {
            let pluginConfiguration = WKWebViewConfiguration()
            pluginConfiguration.websiteDataStore = WKWebsiteDataStore(forIdentifier: plugin.persistentID)
            pluginConfiguration.processPool = WKProcessPool()
            pluginConfiguration.userContentController.addUserScript(try await PluginResources.preflightUserScript)
            pluginConfiguration.userContentController.add(try await PluginResources.filterFilesRuleList)
            if plugin.manifest.permissions?.contains(.networking) != true {
                pluginConfiguration.userContentController.add(try await PluginResources.filterNetworkingRuleList)
            }
            pluginConfiguration.setURLSchemeHandler(PluginURLSchemeHandler(plugin), forURLScheme: "plugin")
            
            let newWebView = WKWebView(frame: .zero, configuration: pluginConfiguration)
            newWebView.navigationDelegate = self
            newWebView.uiDelegate = self
            if newWebView.responds(to: NSSelectorFromString("_setDrawsBackground:")) {
                newWebView.setValue(false, forKey: "drawsBackground")
            } else {
                Self.logger.error("*** -[WKWebView _setDrawsBackground:] removed, plugin appearance will be incorrect")
            }
            newWebView.underPageBackgroundColor = .clear
            
            switch role {
            case .action:
                guard let action = plugin.manifest.action else {
                    throw PluginError.missingRequiredConfiguration("manifest.action")
                }
                let popupURL = URL(string: action.defaultPopup, relativeTo: URL(string: "plugin://")!)
                newWebView.load(URLRequest(url: popupURL!))
            }
            
            self.webView = newWebView
        } catch {
            Self.logger.error("*** Could not create web view for plugin content, reason: \(error)")
            self.webView = nil
            self.error = error
        }
    }
    
    override func layout() {
        super.layout()
        
        let layoutFrame = CGRect(origin: .zero, size: frame.size)
        webView?.frame = layoutFrame
        
        if !errorLabel.isHidden {
            let errorSize = errorLabel.sizeThatFits(frame.size)
            errorLabel.frame = CGRect(x: (layoutFrame.midX - (errorSize.width / 2.0)).rounded(.down),
                                      y: (layoutFrame.midY - (errorSize.height / 2.0)).rounded(.down),
                                      width: errorSize.width,
                                      height: errorSize.height)
        } else {
            errorLabel.frame = .zero
        }
    }
    
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: any Error) {
        Self.logger.error("*** Web view did fail provisional navigation \(String(describing: navigation)), reason: \(error)")
        self.error = error
    }
    
    func webView(_ webView: WKWebView,
                 didFail navigation: WKNavigation!,
                 withError error: any Error) {
        Self.logger.error("*** Web view did fail navigation \(String(describing: navigation)), reason: \(error)")
        self.error = error
    }
}
