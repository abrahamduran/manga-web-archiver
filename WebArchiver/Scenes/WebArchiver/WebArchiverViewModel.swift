//
//  WebArchiverViewModel.swift
//  OfflineWebView
//
//  Created by Abraham Duran on 11/9/22.
//  Copyright © 2022 Ernesto Elsaesser. All rights reserved.
//

import Foundation
import Combine
import WebKit

final class WebArchiverViewModel: ObservableObject {
    @Published private(set) var title = ""

    let webView: WKWebView

    init(url: URL, bookmarkStore: BookmarksStore = .init(), webViewStore: WebViewStore = .init()) {
        self.webView = webViewStore.webView
        webViewStore.webView.load(URLRequest(url: url))
    }
}
