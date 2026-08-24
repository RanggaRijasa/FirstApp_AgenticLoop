//
//  GroceryRepository.swift
//  Cartsyne
//
//  Created by Rangga Rijasa on 19/08/26.
//

import Foundation

/// Boundary the UI and feature models use to read and mutate grocery lists.
///
/// Persistence failures are thrown to callers rather than swallowed so the UI
/// can surface understandable, retryable errors.
@MainActor
protocol GroceryRepository {
    /// Returns all grocery lists.
    func fetchLists() throws -> [GroceryList]

    /// Creates and persists a list with the given name.
    ///
    /// Surrounding whitespace is trimmed and an empty or whitespace-only name
    /// is rejected with ``GroceryListError/emptyName``.
    /// - Returns: the persisted list.
    func createList(named name: String) throws -> GroceryList

    /// Renames an existing list, updating its modification date.
    ///
    /// Surrounding whitespace is trimmed and an empty or whitespace-only name
    /// is rejected with ``GroceryListError/emptyName``.
    func renameList(id: UUID, to name: String) throws

    /// Deletes an existing list.
    func deleteList(id: UUID) throws
}

/// Errors surfaced by grocery-list persistence.
enum GroceryListError: LocalizedError {
    case emptyName
    case notFound

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "The list name can't be empty."
        case .notFound:
            return "That grocery list no longer exists."
        }
    }
}
