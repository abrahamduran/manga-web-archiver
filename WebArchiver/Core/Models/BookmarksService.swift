//
//  BookmarksService.swift
//  WebArchiver
//
//  Created by Abraham Duran on 12/9/22.
//

import Foundation
import Combine

final class BookmarksService: ObservableObject {
    @Published private(set) var history: [Bookmark] = []
    @Published private(set) var latests: [Bookmark] = []
    @Published private(set) var bookmarks: [Bookmark] = []
    private var cancellables = Set<AnyCancellable>()
    let input = Input()

    init() {
        configureSave()
        configureRemove()
        configureRefresh()
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
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink(receiveValue: saveLatests)
            .store(in: &cancellables)

        input.saveBookmark
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .sink(receiveValue: saveBookmarks)
            .store(in: &cancellables)

        input.bulkSave
            .sink { [weak self] (bookmarks, type) in
                guard let self = self else { return }
                self[keyPath: type.keyPath] = bookmarks
                self.store(bookmarks, for: type)
            }
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

extension BookmarksService {
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

        var keyPath: ReferenceWritableKeyPath<BookmarksService, [Bookmark]> {
            switch self {
            case .history:      return \.history
            case .latests:      return \.latests
            case .bookmarks:    return \.bookmarks
            }
        }
    }

    struct Input {
        fileprivate let saveHistory = PassthroughSubject<Bookmark, Never>()
        fileprivate let saveLatests = PassthroughSubject<Bookmark, Never>()
        fileprivate let saveBookmark = PassthroughSubject<Bookmark, Never>()
        fileprivate let bulkSave = PassthroughSubject<([Bookmark], Types), Never>()
        fileprivate let remove = PassthroughSubject<(Types, Bookmark), Never>()
        fileprivate let refresh = PassthroughSubject<Void, Never>()

        func saveHistory(_ bookmark: Bookmark) { saveHistory.send(bookmark) }
        func saveLatests(_ bookmark: Bookmark) { saveLatests.send(bookmark) }
        func saveBookmark(_ bookmark: Bookmark) { saveBookmark.send(bookmark) }
        func bulkSave(_ bookmarks: [Bookmark], in type: Types) { bulkSave.send((bookmarks, type)) }
        func remove(_ bookmark: Bookmark, from type: Types) { remove.send((type, bookmark)) }
        func load() { refresh.send(()) }
    }
}
