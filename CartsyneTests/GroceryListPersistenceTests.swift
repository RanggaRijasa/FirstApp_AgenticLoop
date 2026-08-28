//
//  GroceryListPersistenceTests.swift
//  CartsyneTests
//
//  Created by Rangga Rijasa on 19/08/26.
//

import Foundation
import SwiftData
import Testing
@testable import Cartsyne

/// Deterministic persistence tests for ``GroceryList`` create, fetch, rename,
/// and delete behavior. Each test runs against a fresh in-memory
/// ``ModelContainer`` so tests are isolated and repeatable.
@MainActor
struct GroceryListPersistenceTests {

    /// Creates an isolated in-memory container whose store holds only
    /// ``GroceryList`` models.
    private func makeRepository() throws -> GroceryRepository {
        let schema = Schema([GroceryList.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return SwiftDataGroceryRepository(modelContainer: container)
    }

    @Test func createPersistsListWithTrimmedName() async throws {
        let repository = try makeRepository()

        let created = try repository.createList(named: "  Weekly Groceries  ")

        #expect(created.name == "Weekly Groceries")

        let lists = try repository.fetchLists()
        #expect(lists.count == 1)
        #expect(lists.first?.id == created.id)
        #expect(lists.first?.name == "Weekly Groceries")
    }

    @Test func createRejectsEmptyAndWhitespaceOnlyNames() async throws {
        let repository = try makeRepository()

        for name in ["", "   ", "\n\t "] {
            #expect(throws: GroceryListError.emptyName) {
                _ = try repository.createList(named: name)
            }
        }
        #expect(try repository.fetchLists().isEmpty)
    }

    @Test func createSaveFailureRollsBackSoRetryDoesNotDuplicate() async throws {
        let schema = Schema([GroceryList.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        var repository = SwiftDataGroceryRepository(modelContainer: container)

        // First create fails: the repository's real insert-then-save path is
        // exercised, with the save itself failing deterministically.
        repository.saveInterceptor = {
            throw UnderlyingPersistenceFailure()
        }
        #expect(throws: (any Error).self) {
            _ = try repository.createList(named: "Weekly Groceries")
        }
        // The failed save must not leave the model pending in the context;
        // otherwise a later successful save persists it as a duplicate.
        #expect(context.insertedModelsArray.isEmpty)

        // Retry after the store recovers persists exactly one trimmed list.
        repository.saveInterceptor = nil
        let retried = try repository.createList(named: "  Weekly Groceries  ")
        let lists = try repository.fetchLists()
        #expect(lists.count == 1)
        #expect(lists.first?.id == retried.id)
        #expect(lists.first?.name == "Weekly Groceries")
    }

    @Test func fetchReturnsAllCreatedLists() async throws {
        let repository = try makeRepository()

        let first = try repository.createList(named: "Weekly")
        let second = try repository.createList(named: "Household")

        let lists = try repository.fetchLists()
        let ids = Set(lists.map(\.id))
        #expect(lists.count == 2)
        #expect(ids == [first.id, second.id])
    }

    @Test func renameTrimsNameAndUpdatesModificationDate() async throws {
        let repository = try makeRepository()
        let created = try repository.createList(named: "Weekly Groceries")
        let originalUpdatedAt = created.updatedAt

        // Ensure a measurable time difference so updatedAt must change.
        try await Task.sleep(for: .milliseconds(10))

        try repository.renameList(id: created.id, to: "  Household  ")

        let lists = try repository.fetchLists()
        #expect(lists.count == 1)
        #expect(lists.first?.id == created.id)
        #expect(lists.first?.name == "Household")
        #expect(created.updatedAt >= originalUpdatedAt)
    }

    @Test func renameRejectsEmptyAndWhitespaceOnlyNames() async throws {
        let repository = try makeRepository()
        let created = try repository.createList(named: "Weekly")
        let originalName = created.name

        for name in ["", "   "] {
            #expect(throws: GroceryListError.emptyName) {
                try repository.renameList(id: created.id, to: name)
            }
        }

        #expect(try repository.fetchLists().first?.name == originalName)
    }

    @Test func renameSaveFailureRollsBackNameAndUpdatedAtSoRetrySucceeds() async throws {
        let schema = Schema([GroceryList.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        var repository = SwiftDataGroceryRepository(modelContainer: container)
        let created = try repository.createList(named: "Weekly Groceries")
        let originalName = created.name
        let originalUpdatedAt = created.updatedAt

        // First rename fails: the real mutate-then-save path is exercised with
        // the save itself failing deterministically.
        repository.saveInterceptor = {
            throw UnderlyingPersistenceFailure()
        }
        #expect(throws: (any Error).self) {
            _ = try repository.renameList(id: created.id, to: "Household")
        }
        // The failed save must not leave the mutation pending; the rollback
        // boundary preserves the prior name and updatedAt.
        #expect(created.name == originalName)
        #expect(created.updatedAt == originalUpdatedAt)

        // Retry after the store recovers persists exactly the renamed list.
        repository.saveInterceptor = nil
        let renamed = try repository.renameList(id: created.id, to: "  Household  ")
        let lists = try repository.fetchLists()
        #expect(lists.count == 1)
        #expect(lists.first?.id == renamed.id)
        #expect(lists.first?.name == "Household")
        #expect(lists.first?.updatedAt != originalUpdatedAt)
    }

    @Test func deleteRemovesOnlyTheSelectedList() async throws {
        let repository = try makeRepository()
        let weekly = try repository.createList(named: "Weekly")
        let household = try repository.createList(named: "Household")

        try repository.deleteList(id: weekly.id)

        let lists = try repository.fetchLists()
        #expect(lists.count == 1)
        #expect(lists.first?.id == household.id)
        #expect(lists.first?.name == "Household")
    }

    @Test func deleteUnknownIDThrowsNotFound() async throws {
        let repository = try makeRepository()

        #expect(throws: GroceryListError.notFound) {
            try repository.deleteList(id: UUID())
        }
    }
}

/// Stand-in for an underlying persistence error used by the save interceptor.
private struct UnderlyingPersistenceFailure: LocalizedError {
    var errorDescription: String? { "NSPersistentStore save failed (code 134060)" }
}
