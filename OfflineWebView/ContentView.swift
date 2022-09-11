//
//  ContentView.swift
//  OfflineWebView
//
//  Created by Abraham Duran on 11/9/22.
//  Copyright © 2022 Ernesto Elsaesser. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var service: BookmarksService
    @State private var website: URL?

    var body: some View {
        List {
            Section(header: Text("Sites")) {
                Button("MangaDex") {
                    website = URL(string: "https://mangadex.org")
                }
            }

            Section(header: Text("Bookmarks")) {
                ForEach(service.bookmarks) { bookmark in
                    Button {
                        website = bookmark.url
                    } label: {
                        HStack {
                            Text(bookmark.title)

                            Spacer()

                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.primary)
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            withAnimation {
                                service.remove(bookmark)
                            }
                        }
                    }
                }
            }

            Section(header: Text("Latest Downloads")) {
                ForEach(service.latests.reversed()) { bookmark in
                    Button {
                        website = bookmark.url
                    } label: {
                        HStack {
                            Text(bookmark.title)

                            Spacer()

                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .fullScreenCover(item: $website) { url in
            WebArchiverView(url: url)
        }
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
