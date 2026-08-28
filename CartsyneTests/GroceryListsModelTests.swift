//
//  GroceryListsModelTests.swift
//  CartsyneTests
//
//  Created by Rangga Rijasa on 19/08/26.
//

import Foundation
import SwiftData
import Testing
@testable import Cartsyne

/// Tests for ``GroceryListsModel`` ordering and error handling that do not
/// depend on the UI.
@MainActor
struct GroceryListsModelTests {

    private func makeModel(inserting lists: [GroceryList], save: Bool = true) throws -> GroceryListsModel {
        let schema = Schema([GroceryList.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        for list in lists {
            context.insert(list)
        }
        if save {
            try context.save()
        }
        return GroceryListsModel(
            repository: SwiftDataGroceryRepository(modelContainer: container)
        )
    }

    @Test func loadOrdersByUpdatedAtDescendingThenStableID() throws {
        let older = Date(timeIntervalSince1970: 100)
        let middle = Date(timeIntervalSince1970: 200)
        let newer = Date(timeIntervalSince1970: 300)
        let newestList = GroceryList(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000009")!,
            name: "Newest",
            updatedAt: newer
        )
        let oldestList = GroceryList(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
            name: "Oldest",
            updatedAt: older
        )
        // Two lists share the same updatedAt to exercise the stable tie-break.
        let tiedA = GroceryList(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
            name: "Tied A",
            updatedAt: middle
        )
        let tiedB = GroceryList(
            id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
            name: "Tied B",
            updatedAt: middle
        )

        let model = try makeModel(inserting: [tiedB, oldestList, tiedA, newestList])
        model.load()

        // Newest first; the tied pair follows in ascending stable-id order,
        // then the oldest list.
        #expect(model.lists.map(\.name) == ["Newest", "Tied A", "Tied B", "Oldest"])
    }

    @Test func loadSortsIdenticalUpdatedAtByStableID() throws {
        let now = Date(timeIntervalSince1970: 500)
        let lowID = GroceryList(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "Low", updatedAt: now)
        let highID = GroceryList(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "High", updatedAt: now)

        let model = try makeModel(inserting: [highID, lowID])
        model.load()

        #expect(model.lists.map(\.name) == ["Low", "High"])
    }

    @Test func loadFailureShowsUnderstandableMessageAndRetryRecovers() throws {
        let repository = ScriptedGroceryRepository()
        let model = GroceryListsModel(repository: repository)
        repository.storedLists = [
            GroceryList(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!, name: "Weekly"),
        ]

        repository.fetchError = UnderlyingPersistenceFailure()
        model.load()

        #expect(model.lists.isEmpty)
        // Understandable, retryable message; no raw Swift error text leaks.
        #expect(model.loadError == "Couldn't load your grocery lists. Please try again.")
        #expect(model.loadError?.contains("134060") != true)

        // The Try Again path recovers once the underlying store is reachable.
        repository.fetchError = nil
        model.load()
        #expect(model.loadError == nil)
        #expect(model.lists.map(\.name) == ["Weekly"])
    }

    @Test func createRejectsWhitespaceOnlyNameWithUnderstandableMessage() throws {
        let model = try makeModel(inserting: [])

        let didCreate = model.createList(named: "   ")

        #expect(didCreate == false)
        #expect(model.lists.isEmpty)
        // Understandable validation message, not a raw Swift error.
        #expect(model.createError == "Enter a list name.")
    }

    @Test func createPersistenceFailureKeepsInputShowsFriendlyMessageAndRetrySucceeds() throws {
        let repository = ScriptedGroceryRepository()
        let model = GroceryListsModel(repository: repository)
        let input = "  Weekly Groceries  "

        // A recoverable save failure: the first attempt fails to persist.
        repository.nextCreateError = UnderlyingPersistenceFailure()
        let didCreate = model.createList(named: input)

        #expect(didCreate == false)
        #expect(model.lists.isEmpty)
        #expect(model.createError == "We couldn't create your list. Please try again.")
        #expect(model.createError?.contains("134060") != true)

        // The sheet keeps the entered text; retrying with the same input
        // succeeds and persists exactly one trimmed list.
        let retried = model.createList(named: input)
        #expect(retried == true)
        #expect(model.lists.map(\.name) == ["Weekly Groceries"])
        #expect(model.createError == nil)
    }

    @Test func createPlacesNewListFirstByUpdatedAt() throws {
        let repository = ScriptedGroceryRepository()
        repository.storedLists = [
            GroceryList(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!, name: "Old", updatedAt: Date(timeIntervalSince1970: 100)),
            GroceryList(id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!, name: "Middle", updatedAt: Date(timeIntervalSince1970: 200)),
        ]
        let model = GroceryListsModel(repository: repository)
        model.load()
        #expect(model.lists.map(\.name) == ["Middle", "Old"])

        // A fresh list has the newest updatedAt and is ordered first
        // immediately, before any reload.
        #expect(model.createList(named: "Weekly Groceries") == true)
        #expect(model.lists.map(\.name) == ["Weekly Groceries", "Middle", "Old"])
    }

    @Test func startEditingSelectsListAndClearsPriorError() throws {
        let repository = ScriptedGroceryRepository()
        let list = GroceryList(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!, name: "Weekly")
        repository.storedLists = [list]
        let model = GroceryListsModel(repository: repository)
        model.load()

        // Force a prior error state to prove selection clears it.
        model.renameList(list, to: "   ")
        #expect(model.editError == "Enter a list name.")

        model.startEditing(list)

        #expect(model.editingList?.id == list.id)
        #expect(model.isPresentingEditSheet == true)
        #expect(model.editError == nil)
    }

    @Test func renameRejectsWhitespaceOnlyNameWithUnderstandableMessage() throws {
        let repository = ScriptedGroceryRepository()
        let list = GroceryList(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!, name: "Weekly")
        repository.storedLists = [list]
        let model = GroceryListsModel(repository: repository)
        model.load()
        model.startEditing(list)

        let didRename = model.renameList(list, to: "   ")

        #expect(didRename == false)
        #expect(model.editError == "Enter a list name.")
        // The sheet stays open with the list still selected for retry.
        #expect(model.editingList?.id == list.id)
        #expect(model.lists.map(\.name) == ["Weekly"])
    }

    @Test func renameFailureKeepsPriorNameAndTimestampShowsFriendlyMessageAndRetrySucceeds() throws {
        let repository = ScriptedGroceryRepository()
        let original = Date(timeIntervalSince1970: 100)
        let list = GroceryList(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            name: "Weekly Groceries",
            updatedAt: original
        )
        repository.storedLists = [list]
        let model = GroceryListsModel(repository: repository)
        model.load()
        model.startEditing(list)

        // A recoverable save failure: the first attempt fails to persist.
        repository.nextRenameError = UnderlyingPersistenceFailure()
        let didRename = model.renameList(list, to: "Household")

        #expect(didRename == false)
        #expect(model.editError == "We couldn't rename your list. Please try again.")
        #expect(model.editError?.contains("134060") != true)
        // Rollback boundary: the prior name, timestamp, and selection survive.
        #expect(model.lists.map(\.name) == ["Weekly Groceries"])
        #expect(model.lists.first?.updatedAt == original)
        #expect(model.editingList?.id == list.id)

        // Retry with the same input succeeds and persists the rename.
        let retried = model.renameList(list, to: "Household")
        #expect(retried == true)
        #expect(model.editError == nil)
        #expect(model.lists.map(\.name) == ["Household"])
        #expect(model.lists.first?.updatedAt != original)
    }

    @Test func renameTrimsNameBumpsTimestampAndReordersImmediately() throws {
        let repository = ScriptedGroceryRepository()
        let old = GroceryList(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            name: "Old",
            updatedAt: Date(timeIntervalSince1970: 100)
        )
        let middle = GroceryList(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            name: "Middle",
            updatedAt: Date(timeIntervalSince1970: 200)
        )
        repository.storedLists = [old, middle]
        let model = GroceryListsModel(repository: repository)
        model.load()
        #expect(model.lists.map(\.name) == ["Middle", "Old"])
        model.startEditing(old)

        // Renaming the oldest list gives it the newest timestamp, so it must
        // move to the top immediately, before any reload.
        let didRename = model.renameList(old, to: "  Household  ")

        #expect(didRename == true)
        #expect(model.lists.map(\.name) == ["Household", "Middle"])
        #expect(model.lists.first?.updatedAt ?? .distantPast > middle.updatedAt)
        // The repository's trimmed name is what the home shows.
        #expect(model.lists.first?.name == "Household")
    }
}

/// Deterministic repository double for exercising failure paths a real
/// SwiftData store cannot produce on demand: load failures, recoverable save
/// failures, and one-shot retry behavior.
@MainActor
private final class ScriptedGroceryRepository: GroceryRepository {
    /// Error thrown by the next `fetchLists()` call; `nil` fetches normally.
    var fetchError: (any Error)?
    /// Error thrown by the next `createList` call, consumed by that one call.
    var nextCreateError: (any Error)?
    /// Error thrown by the next `renameList` call, consumed by that one call.
    var nextRenameError: (any Error)?
    /// Lists returned by a successful fetch and appended by successful creates.
    var storedLists: [GroceryList] = []

    func fetchLists() throws -> [GroceryList] {
        if let fetchError {
            throw fetchError
        }
        return storedLists
    }

    func createList(named name: String) throws -> GroceryList {
        if let nextCreateError {
            self.nextCreateError = nil
            throw nextCreateError
        }
        let list = GroceryList(name: name)
        storedLists.append(list)
        return list
    }

    func renameList(id: UUID, to name: String) throws -> GroceryList {
        if let nextRenameError {
            self.nextRenameError = nil
            throw nextRenameError
        }
        // Mirrors the real repository: validate, trim, bump updatedAt, and
        // return the renamed list so the model reflects the persisted state.
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw GroceryListError.emptyName
        }
        guard let index = storedLists.firstIndex(where: { $0.id == id }) else {
            throw GroceryListError.notFound
        }
        let list = storedLists[index]
        list.name = trimmedName
        list.updatedAt = Date()
        return list
    }

    func deleteList(id: UUID) throws {}
}

/// Stand-in for an underlying persistence error; the UI must never expose its
/// technical description to the user.
private struct UnderlyingPersistenceFailure: LocalizedError {
    var errorDescription: String? { "NSPersistentStore save failed (code 134060)" }
}
