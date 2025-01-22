//
//  LibraryID.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/22/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import Foundation

struct LibraryID: RawRepresentable, Hashable, Codable {
    static var unique: Self {
        Self(rawValue: UUID().uuidString)
    }
    
    var rawValue: String
}
