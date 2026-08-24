//
//  AppEnvironment.swift
//  Cartsyne
//
//  Created by Rangga Rijasa on 19/08/26.
//

import Foundation
import SwiftData

/// Builds the app's persistence environment.
///
/// Under normal launches an on-disk store is used so lists survive relaunch.
/// When the `-uiTestInMemoryStore` launch argument is present (used by UI tests
/// that require an isolated, empty store) an in-memory store is used instead.
enum AppEnvironment {
    static let uiTestInMemoryArgument = "-uiTestInMemoryStore"

    /// Creates the ``ModelContainer`` for the ``GroceryList`` schema.
    static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema([GroceryList.self])
        if ProcessInfo.processInfo.arguments.contains(uiTestInMemoryArgument) {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [configuration])
        }
        return try ModelContainer(for: schema)
    }

    /// Creates the repository the home screen uses for list storage.
    static func makeGroceryRepository(container: ModelContainer) -> any GroceryRepository {
        SwiftDataGroceryRepository(modelContainer: container)
    }
}
