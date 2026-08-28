//
//  SwiftDataGroceryRepository.swift
//  Cartsyne
//
//  Created by Rangga Rijasa on 19/08/26.
//

import Foundation
import SwiftData

/// Concrete ``GroceryRepository`` backed by a SwiftData ``ModelContainer``.
///
/// All reads and writes go through the container's main context. Save and
/// fetch failures are rethrown so callers can handle them rather than having
/// them silently ignored.
@MainActor
struct SwiftDataGroceryRepository: GroceryRepository {
    private let modelContainer: ModelContainer

    /// Test seam: when set, replaces the real context save with this closure.
    /// A genuine SwiftData save failure cannot be produced deterministically
    /// through public API (unique constraints merge rather than throw), so
    /// deterministic tests use this to exercise the repository's real
    /// insert-then-failed-save-then-rollback path. Production never sets it.
    var saveInterceptor: (@MainActor () throws -> Void)?

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    private var context: ModelContext {
        modelContainer.mainContext
    }

    func fetchLists() throws -> [GroceryList] {
        let descriptor = FetchDescriptor<GroceryList>()
        return try context.fetch(descriptor)
    }

    func createList(named name: String) throws -> GroceryList {
        let list = try validatedList(named: name)
        context.insert(list)
        try persist()
        return list
    }

    func renameList(id: UUID, to name: String) throws -> GroceryList {
        let trimmedName = try validatedName(name)
        guard let list = try list(withID: id) else {
            throw GroceryListError.notFound
        }
        let previousName = list.name
        let previousUpdatedAt = list.updatedAt
        list.name = trimmedName
        list.updatedAt = Date()
        do {
            try persist()
        } catch {
            // persist() rolled the context back, but SwiftData's rollback
            // discards the context's pending change without restoring the
            // in-memory property values of already-fetched models. Restore
            // the prior name and updatedAt explicitly so callers observe the
            // persisted state, never the failed mutation.
            list.name = previousName
            list.updatedAt = previousUpdatedAt
            throw error
        }
        return list
    }

    func deleteList(id: UUID) throws {
        guard let list = try list(withID: id) else {
            throw GroceryListError.notFound
        }
        context.delete(list)
        try persist()
    }

    /// Saves pending changes, rolling the context back on failure so a failed
    /// save never leaves inserted or mutated models pending. Without the
    /// rollback, a failed create keeps its insert in the context and a later
    /// successful save (for example a retry) persists a duplicate.
    private func persist() throws {
        do {
            if let saveInterceptor {
                try saveInterceptor()
            } else {
                try context.save()
            }
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Builds a new list with a validated (trimmed, non-empty) name.
    private func validatedList(named name: String) throws -> GroceryList {
        let trimmedName = try validatedName(name)
        return GroceryList(name: trimmedName)
    }

    /// Returns a trimmed name or throws ``GroceryListError/emptyName``.
    private func validatedName(_ name: String) throws -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw GroceryListError.emptyName
        }
        return trimmedName
    }

    private func list(withID id: UUID) throws -> GroceryList? {
        var descriptor = FetchDescriptor<GroceryList>()
        descriptor.predicate = #Predicate { list in
            list.id == id
        }
        return try context.fetch(descriptor).first
    }
}
