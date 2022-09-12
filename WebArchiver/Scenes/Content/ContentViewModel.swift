//
//  ContentViewModel.swift
//  WebArchiver
//
//  Created by Abraham Duran on 12/9/22.
//

import Foundation
import Combine
import CombineExt

final class ContentViewModel: ObservableObject {
    @Published var history: [Bookmark] = []
    @Published var latests: [Bookmark] = []
    @Published var bookmarks: [Bookmark] = []
    private var cancellables = Set<AnyCancellable>()
    let input = Input()

    init(bookmarksService: BookmarksService = .init()) {
        configureLoadBookmarks(service: bookmarksService)
        configureHistory(service: bookmarksService)
        configureLatests(service: bookmarksService)
        configureBookmarks(service: bookmarksService)
    }

    private func configureLoadBookmarks(service: BookmarksService) {
        input.load
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                service.input.load()
                self?.history = service.history
                self?.latests = service.latests
                self?.bookmarks = service.bookmarks
            }
            .store(in: &cancellables)
    }

    private func configureHistory(service: BookmarksService) {
        $bookmarks
            .dropFirst()
            .map { ($0, BookmarksService.Types.bookmarks) }
            .sink(receiveValue: service.input.bulkSave)
            .store(in: &cancellables)
    }

    private func configureLatests(service: BookmarksService) {
        $latests
            .dropFirst()
            .map { ($0, BookmarksService.Types.latests) }
            .sink(receiveValue: service.input.bulkSave)
            .store(in: &cancellables)
    }

    private func configureBookmarks(service: BookmarksService) {
        $bookmarks
            .dropFirst()
            .map { ($0, BookmarksService.Types.bookmarks) }
            .sink(receiveValue: service.input.bulkSave)
            .store(in: &cancellables)
    }
}

extension ContentViewModel {
    struct Input {
        fileprivate let load = PassthroughSubject<Void, Never>()

        func loadBookmarks() { load.send(()) }
    }
}

extension Array where Element == Bookmark {
    static var mocks: [Element] {
        [
            .init(title: "Bookmark 1", url: URL(string: "apple.com")!),
            .init(title: "Bookmark 2", url: URL(string: "apple.com/2")!),
            .init(title: "Bookmark 3", url: URL(string: "apple.com/3")!),
            .init(title: "Bookmark 4", url: URL(string: "apple.com/4")!),
            .init(title: "Bookmark 5", url: URL(string: "apple.com/5")!),
            .init(title: "Bookmark 6", url: URL(string: "apple.com/6")!),
            .init(title: "Bookmark 7", url: URL(string: "apple.com/7")!),
            .init(title: "Bookmark 8", url: URL(string: "apple.com/8")!),
            .init(title: "Bookmark 9", url: URL(string: "apple.com/9")!)
        ]
    }
}
