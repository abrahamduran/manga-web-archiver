//
//  URL+Identifiable.swift
//  WebArchiver
//
//  Created by Abraham Duran on 12/9/22.
//

import Foundation

extension URL: Identifiable {
    public var id: String { path }
}
