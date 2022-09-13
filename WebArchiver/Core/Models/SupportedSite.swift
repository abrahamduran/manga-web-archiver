//
//  SupportedSite.swift
//  WebArchiver
//
//  Created by Abraham Duran on 12/9/22.
//

import Foundation

enum SupportedSite: CaseIterable {
    case mangadex

    var title: String {
        switch self {
        case .mangadex: return "MangaDex"
        }
    }

    var url: URL {
        switch self {
        case .mangadex: return URL(string: "https://mangadex.org/")!
        }
    }

    var logoName: String {
        switch self {
        case .mangadex: return "mangadex"
        }
    }
}
