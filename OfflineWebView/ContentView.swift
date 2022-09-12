//
//  ContentView.swift
//  OfflineWebView
//
//  Created by Abraham Duran on 11/9/22.
//  Copyright © 2022 Ernesto Elsaesser. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = BookmarksStore()
    @State private var website: URL?

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Sites")) {
                    NavigationLink("MangaDex") {
                        WebArchiverView(viewModel: .init(url: URL(string: "https://mangadex.org")!))
                    }
                    .foregroundColor(.blue)
                }

                Section(header: Text("Bookmarks")) {
                    ForEach(store.bookmarks) { bookmark in
                        NavigationLink(bookmark.title) {
                            WebArchiverView(viewModel: .init(url: bookmark.url))
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                withAnimation {
                                    store.input.remove(bookmark, from: .bookmarks)
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Latest Downloads")) {
                    ForEach(store.latests) { bookmark in
                        NavigationLink(bookmark.title) {
                            WebArchiverView(viewModel: .init(url: bookmark.url))
                        }
                    }
                }

                Section(header: Text("History")) {
                    ForEach(store.history) { bookmark in
                        NavigationLink(bookmark.title) {
                            WebArchiverView(viewModel: .init(url: bookmark.url))
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: store.input.load)
        }
        .navigationViewStyle(.stack)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension URL: Identifiable {
    public var id: String { path }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
