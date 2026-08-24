//
//  GroceryListsCreateUITests.swift
//  CartsyneUITests
//
//  Created by Rangga Rijasa on 19/08/26.
//

import XCTest

/// Focused UI tests for the Grocery Lists home and create flow.
///
/// Each test launches the app with an isolated in-memory store so the home
/// begins empty and receives no persistence from a real device install.
final class GroceryListsCreateUITests: XCTestCase {

    @MainActor
    func testCreateListFromEmptyStoreShowsRow() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        // Must match AppEnvironment.uiTestInMemoryArgument so the app uses an
        // isolated in-memory store for this deterministic, empty-first test.
        app.launchArguments += ["-uiTestInMemoryStore"]
        app.launch()

        // Empty store renders the documented empty state.
        XCTAssertTrue(
            app.staticTexts["Your grocery lists live here."].waitForExistence(timeout: 5),
            "Empty state should explain where grocery lists live."
        )
        XCTAssertTrue(app.staticTexts["Create a list to start shopping."].exists)

        // Open the create sheet.
        app.buttons["Create List"].firstMatch.tap()
        XCTAssertTrue(app.textFields["List name"].waitForExistence(timeout: 5))

        // Name the list and save it.
        app.textFields["List name"].tap()
        app.textFields["List name"].typeText("Weekly Groceries")
        app.buttons["Create"].tap()

        // The populated home immediately shows the new list.
        XCTAssertTrue(
            app.staticTexts["Weekly Groceries"].waitForExistence(timeout: 5),
            "The newly created list should appear in the populated home."
        )
    }
}
