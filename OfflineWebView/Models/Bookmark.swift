//
//  Bookmark.swift
//  OfflineWebView
//
//  Created by Abraham Duran on 11/9/22.
//  Copyright © 2022 Ernesto Elsaesser. All rights reserved.
//

import Foundation

struct Bookmark: Codable {
    let title: String
    let series: String?
    let url: URL
}

extension Bookmark {
    init(title: String, url: URL) {
        self.title = title
        self.series = nil
        self.url = url
    }
}

extension Bookmark: Identifiable, Hashable {
    var id: String { url.path }
}
