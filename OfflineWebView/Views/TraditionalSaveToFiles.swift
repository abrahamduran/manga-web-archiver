//
//  TraditionalSaveToFiles.swift
//  OfflineWebView
//
//  Created by Abraham Duran on 11/9/22.
//  Copyright © 2022 Ernesto Elsaesser. All rights reserved.
//

import SwiftUI

struct DocumentInteractionController: UIViewControllerRepresentable {

    fileprivate var isExportingDocument: Binding<Bool>
    fileprivate let viewController = UIViewController()
    fileprivate let documentInteractionController: UIDocumentInteractionController

    init(_ isExportingDocument: Binding<Bool>, url: URL) {
        self.isExportingDocument = isExportingDocument
        documentInteractionController = .init(url: url)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentInteractionController>) -> UIViewController { viewController }

    func updateUIViewController(_ controller: UIViewController, context: UIViewControllerRepresentableContext<DocumentInteractionController>) {
        if isExportingDocument.wrappedValue && documentInteractionController.delegate == nil {
            documentInteractionController.uti = documentInteractionController.url?.typeIdentifier ?? "public.data, public.content"
            documentInteractionController.name = documentInteractionController.url?.localizedName
            documentInteractionController.presentOptionsMenu(from: controller.view.frame, in: controller.view, animated: true)
            documentInteractionController.delegate = context.coordinator
            documentInteractionController.presentPreview(animated: true)
        }
    }

    func makeCoordinator() -> Coordintor { .init(self) }

    class Coordintor: NSObject, UIDocumentInteractionControllerDelegate {
        let documentInteractionController: DocumentInteractionController
        init(_ controller: DocumentInteractionController) {
            documentInteractionController = controller
        }
        func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController { documentInteractionController.viewController }

        func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
            controller.delegate = nil
            documentInteractionController.isExportingDocument.wrappedValue = false
        }
    }
}

struct DocumentInteraction: View {
    @State private var isExportingDocument = false
    var body: some View {
        VStack {
            Button("Export Document") { self.isExportingDocument = true }
            .background(DocumentInteractionController($isExportingDocument,
                url: Bundle.main.url(forResource: "cached", withExtension: "webarchive")!))
        }
    }
}

extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var localizedName: String? { (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName }
}

