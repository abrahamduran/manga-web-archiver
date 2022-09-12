//
//  WKWebView+Combine.swift
//  WebArchiver
//
//  Created by Abraham Duran on 12/9/22.
//

import Combine
import WebKit

extension WKWebView {
    func createWebArchiveData() -> Deferred<Future<Data, Error>> {
        Deferred {
            Future {
                self.createWebArchiveData(completionHandler: $0)
            }
        }
    }
}
