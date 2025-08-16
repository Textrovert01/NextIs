//
//  Kid.swift
//  NextIs
//
//  Created by Andy Rodriguez on 8/16/25.
//

import Foundation

struct Kid: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
}
