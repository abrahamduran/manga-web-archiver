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
    private var cancellables = Set<AnyCancellable>()
    let webView: WKWebView

    init(url: URL, bookmarkStore: BookmarksStore = .init()) {
        self.webView = WKWebView(frame: CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1))//webViewStore.webView
        webView.load(URLRequest(url: url))

        configureTitle(webView: webView)
    }

    private func configureTitle(webView: WKWebView) {
        webView.publisher(for: \.title, options: .prior)
            .map(parseChapterTitle)
            .assign(to: &$title)
    }

    private func parseChapterTitle(from webTitle: String?) -> String {
        guard let webTitle = webTitle, webTitle.contains("Chapter") else { return webTitle ?? "" }
        let index = webTitle.firstIndex(of: "C") ?? webTitle.startIndex

        return webTitle[index..<webTitle.endIndex]
            .replacingOccurrences(of: " - MangaDex", with: "")
    }
}
