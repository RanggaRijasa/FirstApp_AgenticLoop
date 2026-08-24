//
//  GroceryListsModel.swift
//  Cartsyne
//
//  Created by Rangga Rijasa on 19/08/26.
//

import Foundation
import Observation
import SwiftData

/// Owns the Grocery Lists home screen state and actions.
///
/// The model is the only place list business logic lives; the view renders
/// what it exposes and forwards user actions to it.
@MainActor
@Observable
final class GroceryListsModel {
    private let repository: any GroceryRepository

    /// Lists shown on the home screen, ordered by most recently updated.
    private(set) var lists: [GroceryList] = []

    /// Understandable message explaining a home-level load failure, if any.
    private(set) var loadError: String?

    /// Understandable message explaining the most recent create failure, if any.
    private(set) var createError: String?

    /// Controls presentation of the create-list sheet.
    var isPresentingCreateSheet = false

    init(repository: any GroceryRepository) {
        self.repository = repository
    }

    /// Loads the grocery lists, keeping the most recently updated first and
    /// breaking ties by stable identifier order.
    func load() {
        do {
            let fetched = try repository.fetchLists()
            lists = fetched.sorted(by: isOrderedBeforeUpdateOrID)
            loadError = nil
        } catch {
            loadError = "Couldn't load your grocery lists. Please try again."
        }
    }

    /// Prepares the home for the create flow: clears any prior create error
    /// and presents the create-list sheet.
    func startCreatingList() {
        createError = nil
        isPresentingCreateSheet = true
    }

    /// Creates a list from the trimmed name.
    ///
    /// - Returns: `true` when the list was created and persisted; `false`
    ///   otherwise. On failure, ``createError`` holds an understandable,
    ///   retryable message and the caller keeps its input available.
    @discardableResult
    func createList(named name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            createError = "Enter a list name."
            return false
        }

        do {
            let created = try repository.createList(named: trimmedName)
            lists.append(created)
            lists.sort(by: isOrderedBeforeUpdateOrID)
            createError = nil
            return true
        } catch let error as GroceryListError where error == .emptyName {
            createError = "Enter a list name."
            return false
        } catch {
            createError = "We couldn't create your list. Please try again."
            return false
        }
    }

    /// Orders lists by `updatedAt` descending, breaking ties by a stable
    /// identifier order so equal timestamps never produce unstable output.
    private func isOrderedBeforeUpdateOrID(_ lhs: GroceryList, _ rhs: GroceryList) -> Bool {
        if lhs.updatedAt != rhs.updatedAt {
            return lhs.updatedAt > rhs.updatedAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }
}
