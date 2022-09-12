//
//  FileManager+Documents.swift
//  OfflineWebView
//
//  Created by Abraham Duran on 11/9/22.
//  Copyright © 2022 Ernesto Elsaesser. All rights reserved.
//

import Foundation

extension FileManager {
    var documentsUrl: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0]
    }
}
