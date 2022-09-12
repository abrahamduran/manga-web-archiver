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
    @ObservedObject var viewModel: WebArchiverViewModel
    @State private var bookmarksDialog = false
    @State private var state = ViewState.idle

//    private let webpageUrl: URL
//    private var webView: WKWebView {
//        store.webView
//    }
//    private let documentsUrl: URL = {
//        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        return urls[0]
//    }()

    init(viewModel: WebArchiverViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .top) {
            WebView(view: viewModel.webView)
                .edgesIgnoringSafeArea(.vertical)
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
//        .onAppear(perform: loadWebsite)
    }

    private var notification: some View {
        Text(notificationMessage)
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
                DispatchQueue.main.asyncAfter(deadline: Constants.Notification.timeout) {
                    changeState(.idle)
                }
            }
    }

    private var toolbar: some View {
        HStack {
            Text("MangaDex")//getChapterTitle(from: store.title ?? ""))
                .bold()
                .onTapGesture(count: 2, perform: { })//back)
                .onLongPressGesture { bookmarksDialog.toggle() }
                .confirmationDialog("Menu", isPresented: $bookmarksDialog, titleVisibility: .hidden, actions: {
                    Button("Add to Bookmarks", action: { })//bookmark)
                    Button("Home", role: .destructive, action: dismiss)
                })

            Spacer()

            if state == .saving {
                ProgressView()
                    .padding(.trailing)
            } else {
                Button(action: { }) {//save) {
                    Text("Save").bold()
                }
                .disabled(state != .idle)
            }
        }
    }

//    private func loadWebsite() {
//        store.webView.load(URLRequest(url: webpageUrl))
//    }

//    private func back() {
//        webView.goBack()
//    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }

//    private func bookmark() {
//        service.input.saveBookmark(
//            Bookmark(title: store.title!, url: store.url!)
//        )
//    }

//    private func save() {
//        guard let url = store.url, let title = store.title else { return }
//        let impact = UINotificationFeedbackGenerator()
//        impact.prepare()
//
//        let fileName = getChapterTitle(from: title)
//        let folderName = getSeriesName(from: title)
//
//        changeState(.saving)
//
//        let directoryUrl = documentsUrl
//            .appendingPathComponent(folderName)
//        let destinationUrl = directoryUrl
//            .appendingPathComponent(fileName)
//            .appendingPathExtension("webarchive")
//
//        if !FileManager.default.fileExists(atPath: directoryUrl.path) {
//            try? FileManager.default.createDirectory(at: directoryUrl, withIntermediateDirectories: false)
//        }
//
//        webView.createWebArchiveData { result in
//            switch result {
//            case let .success(data):
//                do {
//                    try data.write(to: destinationUrl)
//                    DispatchQueue.global(qos: .userInitiated).async {
//                        service.markSaved(Bookmark(title: fileName, series: folderName, url: url))
//                    }
//                    DispatchQueue.main.async {
//                        changeState(.saved)
//                        impact.notificationOccurred(.success)
//                    }
//                } catch {
//                    print("ERROR:", error)
//                    changeState(.error)
//                    impact.notificationOccurred(.error)
//                }
//            case let .failure(error):
//                print("ERROR:", error)
//                changeState(.error)
//                impact.notificationOccurred(.error)
//            }
//        }
//    }

//    private func remove() {
//        guard let title = store.title else { return }
//
//        let destinationUrl = documentsUrl
//            .appendingPathComponent(title)
//            .appendingPathExtension("webarchive")
//
//        if FileManager.default.fileExists(atPath: destinationUrl.path) {
//            try? FileManager.default.removeItem(at: destinationUrl)
//        }
//    }

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

extension WebArchiverView {
    enum ViewState { case idle, saving, saved, error }

    enum Constants {
        enum Notification {
            static let success = "Saved!"
            static let failure = "Something went wrong"
            static var timeout: DispatchTime {
                DispatchTime.now() + 4
            }
        }
    }

    var notificationMessage: String {
        if state == .error {
            return Constants.Notification.failure
        }

        return Constants.Notification.success
    }
}


struct WebArchiverView_Previews: PreviewProvider {
    static var previews: some View {
        WebArchiverView(viewModel: .init(url: URL(string: "https://mangadex.org")!))
    }
}
