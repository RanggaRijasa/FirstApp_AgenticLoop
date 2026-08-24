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
        try context.save()
        return list
    }

    func renameList(id: UUID, to name: String) throws {
        let trimmedName = try validatedName(name)
        guard let list = try list(withID: id) else {
            throw GroceryListError.notFound
        }
        list.name = trimmedName
        list.updatedAt = Date()
        try context.save()
    }

    func deleteList(id: UUID) throws {
        guard let list = try list(withID: id) else {
            throw GroceryListError.notFound
        }
        context.delete(list)
        try context.save()
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
