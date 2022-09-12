//
//  ContentView.swift
//  WebArchiver
//
//  Created by Abraham Duran on 12/9/22.
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
            .navigationTitle("Web Archiver")
            .listStyle(InsetGroupedListStyle())
            .onAppear(perform: store.input.load)
        }

        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
