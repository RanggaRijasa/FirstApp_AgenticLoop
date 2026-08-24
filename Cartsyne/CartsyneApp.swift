//
//  CartsyneApp.swift
//  Cartsyne
//
//  Created by Rangga Rijasa on 19/08/26.
//

import SwiftData
import SwiftUI

@main
struct CartsyneApp: App {
    private let modelContainer: ModelContainer
    private let groceryListsModel: GroceryListsModel

    init() {
        // A container build failure is a fatal launch error; the app cannot
        // run without persistence.
        guard let container = try? AppEnvironment.makeModelContainer() else {
            fatalError("Unable to create the model container.")
        }
        modelContainer = container
        groceryListsModel = GroceryListsModel(
            repository: AppEnvironment.makeGroceryRepository(container: container)
        )
    }

    var body: some Scene {
        WindowGroup {
            GroceryListsView(model: groceryListsModel)
        }
        .modelContainer(modelContainer)
    }
}
