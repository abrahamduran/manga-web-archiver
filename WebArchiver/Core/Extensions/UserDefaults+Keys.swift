//
//  UserDefaults+Keys.swift
//  OfflineWebView
//
//  Created by Abraham Duran on 11/9/22.
//  Copyright © 2022 Ernesto Elsaesser. All rights reserved.
//

import Foundation

extension UserDefaults {
    enum Key: String {
        case history
        case latests = "latest_downloads"
        case bookmarks = "saved_bookmarks"
    }
}
