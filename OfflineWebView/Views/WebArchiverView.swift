//
//  WebArchiverView.swift
//  OfflineWebView
//
//  Created by Ernesto Elsäßer on 27.03.20.
//  Copyright © 2020 Ernesto Elsaesser. All rights reserved.
//

import SwiftUI
import Combine
import WebKit

struct WebArchiverView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var service: BookmarksService
    @StateObject private var store = WebViewStore()
    @State private var state = ViewState.idle
    @State private var bookmarksDialog = false

    private let webpageUrl: URL
    private var webView: WKWebView {
        store.webView
    }
    private let documentsUrl: URL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0]
    }()

    init(url: URL) {
        self.webpageUrl = url
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                WebView(view: webView)
                    .ignoresSafeArea(.container, edges: .top)
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) {
                            toolbar
                        }
                    }

                if [.saved, .error].contains(state) {
                    notification
                        .zIndex(1)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .onAppear {
            store.webView.load(URLRequest(url: webpageUrl))
        }
    }

    private var notification: some View {
        Text(state == .saved ? "Saved!" : "Something went wrong")
            .font(.body.bold())
            .foregroundColor(.primary)
            .padding(.vertical)
            .frame(maxWidth: .infinity)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .edgesIgnoringSafeArea(.top)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .onTapGesture { changeState(.idle) }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + (state == .saved ? 2 : 3)) {
                    changeState(.idle)
                }
            }
    }

    private var toolbar: some View {
        HStack {
            Text(getChapterTitle(from: store.title ?? ""))
                .bold()
                .onTapGesture(count: 2, perform: back)
                .onLongPressGesture { bookmarksDialog.toggle() }
                .confirmationDialog("Menu", isPresented: $bookmarksDialog, titleVisibility: .hidden, actions: {
                    Button("Add to Bookmarks", action: bookmark)
                    Button("Home", role: .destructive, action: dismiss)
                })

            Spacer()

            if state == .saving {
                ProgressView()
                    .padding(.trailing)
            } else {
                Button(action: save) {
                    Text("Save").bold()
                }
                .disabled(state != .idle)
            }
        }
    }

    private func back() {
        webView.goBack()
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }

    private func bookmark() {
        service.add(
            Bookmark(title: store.title!, url: store.url!)
        )
    }

    private func save() {
        guard let url = store.url, let title = store.title else { return }
        let impact = UIImpactFeedbackGenerator(style: .light)

        let fileName = getChapterTitle(from: title)
        let folderName = getSeriesName(from: title)

        changeState(.saving)

        let directoryUrl = documentsUrl
            .appendingPathComponent(folderName)
        let destinationUrl = directoryUrl
            .appendingPathComponent(fileName)
            .appendingPathExtension("webarchive")

        if !FileManager.default.fileExists(atPath: directoryUrl.path) {
            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false)
        }

        webView.createWebArchiveData { result in
            switch result {
            case let .success(data):
                do {
                    try data.write(to: destinationUrl)
                    service.markSaved(Bookmark(title: fileName, series: folderName, url: url))
                    changeState(.saved)
                    impact.impactOccurred()
                } catch {
                    print("ERROR:", error)
                    changeState(.error)
                }
            case let .failure(error):
                print("ERROR:", error)
                changeState(.error)
            }
        }
    }

    private func remove() {
        guard let title = store.title else { return }

        let destinationUrl = documentsUrl
            .appendingPathComponent(title)
            .appendingPathExtension("webarchive")

        if FileManager.default.fileExists(atPath: destinationUrl.path) {
            try? FileManager.default.removeItem(at: destinationUrl)
        }
    }

    private func getChapterTitle(from webTitle: String) -> String {
        guard webTitle.contains("Chapter") else { return webTitle }
        let index = webTitle.firstIndex(of: "C") ?? webTitle.startIndex

        return webTitle[index..<webTitle.endIndex]
            .replacingOccurrences(of: " - MangaDex", with: "")
    }

    private func getSeriesName(from webTitle: String) -> String {
        guard webTitle.contains("Chapter"),
              let start = webTitle.firstIndex(of: "-"),
              let end = webTitle.lastIndex(of: "-")
        else { return "Unknown" }

        return webTitle[start..<end]
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "~", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private func changeState(_ newState: ViewState) {
        withAnimation(.easeInOut) {
            state = newState
        }
    }
}

enum ViewState { case idle, saving, saved, error }

struct WebArchiverView_Previews: PreviewProvider {
    static var previews: some View {
        WebArchiverView(url: URL(string: "https://mangadex.org")!)
    }
}
