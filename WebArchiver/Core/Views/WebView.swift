//
//  WebView.swift
//  OfflineWebView
//
//  Created by Abraham Duran on 11/9/22.
//

import SwiftUI
import Combine
import WebKit

public struct WebView: UIViewRepresentable {
    public let webView: WKWebView

    public init(view: WKWebView) {
        self.webView = view
    }

    public func makeUIView(context: UIViewRepresentableContext<WebView>) -> WKWebView {
        webView
    }

    public func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
    }
}
