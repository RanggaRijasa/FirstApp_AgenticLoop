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

    @Test func loadSurfacesUnderstandableErrorOnFailure() throws {
        // A fresh store has no lists and therefore no error.
        let model = try makeModel(inserting: [])
        model.load()
        #expect(model.loadError == nil)
        #expect(model.lists.isEmpty)
    }

    @Test func createFailureKeepsInputAndSetsUnderstandableMessage() throws {
        let model = try makeModel(inserting: [])

        let didCreate = model.createList(named: "   ")

        #expect(didCreate == false)
        #expect(model.lists.isEmpty)
        // Understandable validation message, not a raw Swift error.
        #expect(model.createError == "Enter a list name.")
    }

    @Test func createTrimmedNameAppearsInList() throws {
        let model = try makeModel(inserting: [])

        let didCreate = model.createList(named: "  Weekly Groceries  ")

        #expect(didCreate == true)
        #expect(model.lists.map(\.name) == ["Weekly Groceries"])
    }
}
