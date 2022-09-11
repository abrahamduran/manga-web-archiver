//
//  BookmarksService.swift
//  OfflineWebView
//
//  Created by Abraham Duran on 11/9/22.
//  Copyright © 2022 Ernesto Elsaesser. All rights reserved.
//

import Foundation
import Combine

final class BookmarksService: ObservableObject {
    @Published private(set) var latests: [Bookmark] = []
    @Published private(set) var bookmarks: [Bookmark] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: "saved_bookmarks") {
            let bookmarks = try? JSONDecoder().decode([Bookmark].self, from: data)
            self.bookmarks = bookmarks ?? []
        }

        if let data = UserDefaults.standard.data(forKey: "latest_downloads") {
            let latests = try? JSONDecoder().decode([Bookmark].self, from: data)
            self.latests = latests ?? []
        }
    }

    deinit {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: "saved_bookmarks")
        }
        if let data = try? JSONEncoder().encode(latests) {
            UserDefaults.standard.set(data, forKey: "latest_downloads")
        }
    }

    func add(_ bookmark: Bookmark) {
        guard !bookmarks.contains(where: { $0.id == bookmark.id }) else { return }

        bookmarks.append(bookmark)
        updateUserDefaults()
    }

    func remove(_ bookmark: Bookmark) {
        guard let index = bookmarks.firstIndex(where: { $0.id == bookmark.id }) else { return }

        bookmarks.remove(at: index)
        updateUserDefaults()
    }

    func markSaved(_ bookmark: Bookmark) {
        if bookmark.series != nil, let index = latests.firstIndex(where: { $0.series == bookmark.series }) {
            latests.remove(at: index)
            latests.append(bookmark)
        } else {
            latests.append(bookmark)
        }

        if latests.count > 20 {
            latests.removeLast()
        }

        if let data = try? JSONEncoder().encode(latests) {
            UserDefaults.standard.set(data, forKey: "latest_downloads")
        }
    }

    private func updateUserDefaults() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: "saved_bookmarks")
        }
    }
}
