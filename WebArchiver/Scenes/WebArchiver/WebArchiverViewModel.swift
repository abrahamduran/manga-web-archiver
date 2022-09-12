//
//  WebArchiverViewModel.swift
//  OfflineWebView
//
//  Created by Abraham Duran on 11/9/22.
//  Copyright © 2022 Ernesto Elsaesser. All rights reserved.
//

import Foundation
import Combine
import CombineExt
import WebKit

final class WebArchiverViewModel: ObservableObject {
    @Published private(set) var title = ""
    @Published private(set) var state = ViewState.idle
    private var cancellables = Set<AnyCancellable>()
    let webView: WKWebView
    let input = Input()

    init(url: URL, bookmarkStore: BookmarksStore = .init()) {
        self.webView = WKWebView(frame: CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1))
        webView.load(URLRequest(url: url))
//        webView.navigationDelegate = self

        configureIdleStateReset()
        configureTitle(webView: webView)
        configureGoBack(webView: webView)
        configureArchiveWebpage(webView: webView, store: bookmarkStore)
        configureAddToHistory(webView: webView, store: bookmarkStore)
        configureAddToBookmark(webView: webView, store: bookmarkStore)
    }

    private func configureIdleStateReset() {
        $state
            .filter { [.saved, .error].contains($0) }
            .map { _ in ViewState.idle }
            .debounce(for: .seconds(4), scheduler: DispatchQueue.main)
            .assign(to: &$state)
    }

    private func configureTitle(webView: WKWebView) {
        webView.publisher(for: \.title, options: .prior)
            .map(parseChapterTitle)
            .assign(to: &$title)
    }

    private func configureGoBack(webView: WKWebView) {
        input.back
            .sink { webView.goBack() }
            .store(in: &cancellables)
    }

    private func configureArchiveWebpage(webView: WKWebView, store: BookmarksStore) {
        let archive = input.archive.share()

        archive
            .map { ViewState.saving }
            .assign(to: &$state)

        let fileInfo = archive
            .compactMap { [parseChapterTitle, parseSeriesName] _ -> (title: String, series: String, url: URL, directory: URL)? in
                guard webView.title != nil, let url = webView.url else { return nil }
                let title = parseChapterTitle(webView.title)
                let series = parseSeriesName(title)

                return (title: title, series: series, url: url, directory: .documents.appendingPathComponent(series))
            }
            .share()

        let createDirectory = fileInfo
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .map {
                (FileManager.default.fileExists(atPath: $0.directory.path), $0.directory)
            }
            .flatMap { (exists, directory) -> Just<Bool> in
                guard exists == false else { return Just(true) }
                do {
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
                    return Just(true)
                } catch {
                    debugPrint(#file, error)
                    return Just(false)
                }
            }

        let destination = fileInfo
            .map {
                return $0.directory
                    .appendingPathComponent($0.title)
                    .appendingPathExtension("webarchive")
            }

        let webArchive = createDirectory
            .flatMap { exists -> AnyPublisher<Data?, Never> in
                guard exists else { return Just(nil).eraseToAnyPublisher() }

                return webView.createWebArchiveData()
                    .map { $0 }
                    .catch({ error -> Just<Data?> in
                        debugPrint(#file, error)

                        return Just(nil)
                    })
                    .eraseToAnyPublisher()
            }

        let saveToDestination = webArchive
            .combineLatest(destination)
            .flatMap { (data, destination) -> Just<Bool> in
                guard let data = data else { return Just(false) }
                do {
                    try data.write(to: destination)
                    return Just(true)
                } catch {
                    debugPrint(#file, error)
                    return Just(false)
                }
            }

        saveToDestination
            .filter { $0 }
            .withLatestFrom(fileInfo)
            .map { Bookmark(title: $0.title, series: $0.series, url: $0.url) }
            .sink(receiveValue: store.input.saveLatests)
            .store(in: &cancellables)

        saveToDestination
            .map { $0 ? ViewState.saved : .error }
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
    }

    private func configureAddToBookmark(webView: WKWebView, store: BookmarksStore) {
        input.bookmark
            .compactMap { [parseChapterTitle] _ -> Bookmark? in
                guard let url = webView.url else { return nil }
                let title = parseChapterTitle(webView.title)

                return Bookmark(title: title, url: url)
            }
            .sink(receiveValue: store.input.saveBookmark)
            .store(in: &cancellables)
    }

    private var observers: [NSKeyValueObservation] = []
    private func configureAddToHistory(webView: WKWebView, store: BookmarksStore) {
        webView.publisher(for: \.url, options: [.new])
            .removeDuplicates()
            .compactMap { $0 }
            .combineLatest(
                webView.publisher(for: \.title, options: [.new])
                    .removeDuplicates()
                    .compactMap { $0 }
            )
            .filter {
                SupportedSite.allCases.map(\.url).contains($0.0) == false
            }
            .debounce(for: .seconds(10), scheduler: DispatchQueue.main)
            .compactMap { (url, title) -> Bookmark? in
                guard !title.isEmpty else { return nil }

                return Bookmark(title: title, url: url)
            }
            .sink(receiveValue: store.input.saveHistory)
            .store(in: &cancellables)
    }

    private func parseChapterTitle(from webTitle: String?) -> String {
        guard let webTitle = webTitle, webTitle.contains("Chapter") else { return webTitle ?? "" }
        let index = webTitle.firstIndex(of: "C") ?? webTitle.startIndex

        return webTitle[index..<webTitle.endIndex]
            .replacingOccurrences(of: " - MangaDex", with: "")
    }

    private func parseSeriesName(from webTitle: String?) -> String {
        guard let webTitle = webTitle, webTitle.contains("Chapter"),
              let start = webTitle.firstIndex(of: "-"),
              let end = webTitle.lastIndex(of: "-")
        else { return "Unknown" }

        return webTitle[start..<end]
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "~", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}

//extension WebArchiverViewModel: WKNavigationDelegate {
//
//}

extension WebArchiverViewModel {
    enum ViewState { case idle, saving, saved, error }

    struct Input {
        fileprivate let back = PassthroughSubject<Void, Never>()
        fileprivate let archive = PassthroughSubject<Void, Never>()
        fileprivate let bookmark = PassthroughSubject<Void, Never>()

        func goBack() { back.send(()) }
        func addToBookmark() { bookmark.send(()) }
        func archiveWebpage() { archive.send(()) }
    }
}

private extension URL {
    static var documents: URL {
        FileManager.documentsUrl
    }
}
