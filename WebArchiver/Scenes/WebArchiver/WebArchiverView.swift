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
    @ObservedObject private var viewModel: WebArchiverViewModel
    @State private var bookmarksDialog = false
    private let generator = UINotificationFeedbackGenerator()

    init(viewModel: WebArchiverViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .top) {
            WebView(view: viewModel.webView)
                .edgesIgnoringSafeArea(.vertical)

            if viewModel.state == .saved {
                savedNotification
                    .zIndex(1)
            } else if viewModel.state == .error {
                errorNotification
                    .zIndex(1)
            }
        }
        .animation(.default, value: viewModel.state)
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                toolbar
            }
        }
        .onAppear(perform: viewModel.input.loadPage)
        .onChange(of: viewModel.state) { newValue in
            switch newValue {
            case .saving:   generator.prepare()
            case .saved:    generator.notificationOccurred(.success)
            case .error:    generator.notificationOccurred(.error)
            case .idle:     return
            }
        }
    }

    private var savedNotification: some View {
        Text(Constants.Notification.saved)
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
    }

    private var errorNotification: some View {
        GeometryReader { proxy in
            Text(Constants.Notification.error)
                .font(.body.bold())
                .foregroundColor(.primary.opacity(0.75))
                .padding()
                .multilineTextAlignment(.center)
                .frame(width: proxy.size.width * 0.5,
                       height: proxy.size.height * 0.2)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.15))
                        )
                )
                .transition(.opacity)
                .offset(x: (proxy.size.width * 0.5) / 2,
                        y: proxy.size.height * 0.4)
        }
    }

    private var toolbar: some View {
        HStack {
            Text(viewModel.title)
                .bold()
                .onTapGesture(count: 2, perform: viewModel.input.goBack)
                .onLongPressGesture { bookmarksDialog.toggle() }
                .confirmationDialog("Menu", isPresented: $bookmarksDialog, titleVisibility: .hidden, actions: {
                    Button("Add to Bookmarks", action: viewModel.input.addToBookmark)
                    Button("Home", role: .destructive, action: dismiss)
                })

            Spacer()

            Button(action: viewModel.input.archiveWebpage) {
                Text("Archive").bold()
            }
            .disabled(viewModel.state != .idle)
        }
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

private extension WebArchiverView {
    enum Constants {
        enum Notification {
            static let saved = "Saved!"
            static let error = "Something went wrong"
            static var timeout: DispatchTime {
                DispatchTime.now() + 4
            }
        }
    }
}


struct WebArchiverView_Previews: PreviewProvider {
    static var previews: some View {
        WebArchiverView(viewModel: .init(url: URL(string: "https://mangadex.org")!))
    }
}
