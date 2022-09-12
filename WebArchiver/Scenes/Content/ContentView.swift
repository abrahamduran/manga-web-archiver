//
//  ContentView.swift
//  WebArchiver
//
//  Created by Abraham Duran on 12/9/22.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var editMode = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Sites")) {
                    ForEach(SupportedSite.allCases, id: \.self) { site in
                        NavigationLink(site.title) {
                            WebArchiverView(viewModel: .init(url: site.url))
                        }
                        .foregroundColor(.blue)
                    }
                }

                BookmarkSection(title: "Bookmarks", bookmarks: $viewModel.bookmarks, editMode: $editMode)

                BookmarkSection(title: "Latest Downloads", bookmarks: $viewModel.latests, editMode: $editMode)

                BookmarkSection(title: "History", bookmarks: $viewModel.history, editMode: $editMode)
            }
            .navigationTitle("Web Archiver")
            .listStyle(InsetGroupedListStyle())
            .onAppear(perform: viewModel.input.loadBookmarks)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if editMode {
                        doneButton
                    }
                }
            }
            .gesture(MagnificationGesture()
                .onEnded { _ in
                    withAnimation { editMode.toggle() }
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var doneButton: some View {
        Button {
            withAnimation { editMode.toggle() }
        } label: {
            Text("Done").bold()
        }
        .transition(.opacity)
    }
}

struct BookmarkSection: View {
    let title: String
    @Binding var bookmarks: [Bookmark]
    @Binding var editMode: Bool

    var body: some View {
        Section(header: Text(title)) {
            if editMode, bookmarks.isEmpty == false {
                Button(role: .destructive) {
                    withAnimation {
                        bookmarks.removeAll()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Clear \(title)")
                        Image(systemName: "trash")
                        Spacer()
                    }
                }
            }

            ForEach(bookmarks) { bookmark in
                NavigationLink(bookmark.title) {
                    WebArchiverView(viewModel: .init(url: bookmark.url))
                }
            }
            .onDelete { index in
                bookmarks.remove(atOffsets: index)
            }
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
