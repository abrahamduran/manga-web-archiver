//
//  UIViewWrapper.swift
//  OfflineWebView
//
//  Created by Ernesto Elsäßer on 27.03.20.
//  Copyright © 2020 Ernesto Elsaesser. All rights reserved.
//

import SwiftUI
import Combine
import WebKit

struct UIViewWrapper: UIViewRepresentable {
    
    let view: UIView
    
    func makeUIView(context: Context) -> UIView  {
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

@dynamicMemberLookup
public class WebViewStore: ObservableObject {
    @Published public var webView: WKWebView {
        didSet {
            setupObservers()
        }
    }

    public init(webView: WKWebView = WKWebView()) {
        self.webView = webView
        setupObservers()
    }

    private func setupObservers() {
        func subscriber<Value>(for keyPath: KeyPath<WKWebView, Value>) -> NSKeyValueObservation {
            return webView.observe(keyPath, options: [.prior]) { _, change in
                if change.isPrior {
                    self.objectWillChange.send()
                }
            }
        }
        // Setup observers for all KVO compliant properties
        observers = [
            subscriber(for: \.title),
            subscriber(for: \.url),
            subscriber(for: \.isLoading),
            subscriber(for: \.estimatedProgress),
            subscriber(for: \.hasOnlySecureContent),
            subscriber(for: \.serverTrust),
            subscriber(for: \.canGoBack),
            subscriber(for: \.canGoForward),
            subscriber(for: \.themeColor),
            subscriber(for: \.underPageBackgroundColor),
            subscriber(for: \.microphoneCaptureState),
            subscriber(for: \.cameraCaptureState),
            subscriber(for: \.fullscreenState)
        ]
    }

    private var observers: [NSKeyValueObservation] = []

    public subscript<T>(dynamicMember keyPath: KeyPath<WKWebView, T>) -> T {
        webView[keyPath: keyPath]
    }
}

/// A container for using a WKWebView in SwiftUI
public struct WebView: View, UIViewRepresentable {
    /// The WKWebView to display
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
