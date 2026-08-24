//
//  GroceryList.swift
//  Cartsyne
//
//  Created by Rangga Rijasa on 19/08/26.
//

import Foundation
import SwiftData

/// A persisted grocery list.
///
/// The model enforces the durable list invariants:
/// - a stable, unique identifier,
/// - a non-empty name with surrounding whitespace trimmed,
/// - separate creation and modification dates.
@Model
final class GroceryList {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        precondition(!trimmedName.isEmpty, "GroceryList requires a non-empty name")
        self.id = id
        self.name = trimmedName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
