//
//  BookmarksStore.swift
//  OfflineWebView
//
//  Created by Abraham Duran on 11/9/22.
//  Copyright © 2022 Ernesto Elsaesser. All rights reserved.
//

import Foundation
import Combine

final class BookmarksStore: ObservableObject {
    @Published private(set) var history: [Bookmark] = []
    @Published private(set) var latests: [Bookmark] = []
    @Published private(set) var bookmarks: [Bookmark] = []
    private var cancellables = Set<AnyCancellable>()
    let input = Input()

    struct Input {
        fileprivate let saveHistory = PassthroughSubject<Bookmark, Never>()
        fileprivate let saveLatests = PassthroughSubject<Bookmark, Never>()
        fileprivate let saveBookmark = PassthroughSubject<Bookmark, Never>()
        fileprivate let remove = PassthroughSubject<(Types, Bookmark), Never>()
        fileprivate let refresh = PassthroughSubject<Void, Never>()

        func saveHistory(_ bookmark: Bookmark) { saveHistory.send(bookmark) }
        func saveLatests(_ bookmark: Bookmark) { saveLatests.send(bookmark) }
        func saveBookmark(_ bookmark: Bookmark) { saveBookmark.send(bookmark) }
        func remove(_ bookmark: Bookmark, from type: Types) { remove.send((type, bookmark)) }
        func load() { refresh.send(()) }
    }

    init() {
        load(.history, .latests, .bookmarks)
    }

    deinit {
        store(.history, .latests, .bookmarks)
    }

    private func configureRefresh() {
        input.refresh
            .sink { [weak self] in
                self?.load(.history, .latests, .bookmarks)
            }
            .store(in: &cancellables)
    }

    private func configureSave() {
        input.saveHistory
            .receive(on: DispatchQueue.global())
            .sink(receiveValue: saveHistory)
            .store(in: &cancellables)

        input.saveLatests
            .receive(on: DispatchQueue.global())
            .sink(receiveValue: saveLatests)
            .store(in: &cancellables)

        input.saveBookmark
            .receive(on: DispatchQueue.global())
            .sink(receiveValue: saveBookmarks)
            .store(in: &cancellables)
    }

    private func configureRemove() {
        input.remove
            .receive(on: DispatchQueue.global())
            .sink { [weak self] (type, bookmark) in
                guard let self = self else { return }
                var array = self[keyPath: type.keyPath]

                if let index = array.firstIndex(where: { $0.id == bookmark.id }) {
                    array.remove(at: index)
                }

                self.store(array, for: type)
            }
            .store(in: &cancellables)
    }

    private func saveLatests(_ bookmark: Bookmark) {
        var array = latests
        if bookmark.series != nil,
           let index = array.firstIndex(where: { $0.series == bookmark.series || $0.id == bookmark.id }) {
            array.remove(at: index)
            array.append(bookmark)
        } else {
            array.append(bookmark)
        }

        if array.count > Constants.latestsLimit {
            array.removeLast()
        }

        store(array.reversed(), for: .latests)
    }

    private func saveHistory(_ bookmark: Bookmark) {
        var array = history
        if let index = array.firstIndex(where: { $0.id == bookmark.id }) {
            array.remove(at: index)
            array.append(bookmark)
        } else {
            array.append(bookmark)
        }

        if array.count > Constants.historyLimit {
            array.removeLast()
        }

        store(array.reversed(), for: .history)
    }

    private func saveBookmarks(_ bookmark: Bookmark) {
        var array = bookmarks
        if let index = array.firstIndex(where: { $0.id == bookmark.id }) {
            array[index] = bookmark
        } else {
            array.append(bookmark)
        }

        store(array.reversed(), for: .bookmarks)
    }

    private func load(_ types: Types...) {
        for type in types {
            if let data = UserDefaults.standard.data(forKey: type.key.rawValue) {
                let array = try? JSONDecoder().decode([Bookmark].self, from: data)
                self[keyPath: type.keyPath] = array ?? []
            }
        }
    }

    private func store(_ types: Types...) {
        for type in types {
            store(self[keyPath: type.keyPath], for: type)
        }
    }

    private func store(_ array: [Bookmark], for type: Types) {
        if let data = try? JSONEncoder().encode(array) {
            UserDefaults.standard.set(data, forKey: type.key.rawValue)
        }
    }
}

extension BookmarksStore {
    enum Constants {
        static let latestsLimit = 20
        static let historyLimit = 50
    }
    enum Types {
        case history, latests, bookmarks

        var key: UserDefaults.Key {
            switch self {
            case .history:      return .history
            case .latests:      return .latests
            case .bookmarks:    return .bookmarks
            }
        }

        var keyPath: ReferenceWritableKeyPath<BookmarksStore, [Bookmark]> {
            switch self {
            case .history:      return \.history
            case .latests:      return \.latests
            case .bookmarks:    return \.bookmarks
            }
        }
    }
}
