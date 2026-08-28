//
//  GroceryListsCreateUITests.swift
//  CartsyneUITests
//
//  Created by Rangga Rijasa on 19/08/26.
//

import XCTest

/// Focused UI tests for the Grocery Lists home and create flow.
///
/// `testCreateListFromEmptyStoreShowsRow` launches with an isolated in-memory
/// store so the home begins empty and receives no persistence from a real
/// device install. `testCreatedListPersistsAfterRelaunch` uses the real
/// on-disk store because persistence across relaunch is what it verifies.
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
        let nameField = app.textFields["List name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))

        // The name field must be focused automatically on presentation:
        // typing succeeds without ever tapping the field.
        nameField.typeText("Weekly Groceries")
        app.buttons["Create"].tap()

        // The sheet is dismissed and the populated home immediately shows
        // the new list.
        XCTAssertFalse(
            nameField.waitForExistence(timeout: 2),
            "The create sheet should dismiss after a successful save."
        )
        XCTAssertTrue(
            app.staticTexts["Weekly Groceries"].waitForExistence(timeout: 5),
            "The newly created list should appear in the populated home."
        )
    }

    @MainActor
    func testCreatedListPersistsAfterRelaunch() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        // No -uiTestInMemoryStore argument: this test verifies that a list
        // created in the real on-disk store survives a full app relaunch.
        app.launch()

        app.buttons["Create List"].firstMatch.tap()
        let nameField = app.textFields["List name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))

        // Again typed without tapping the field: automatic sheet focus.
        nameField.typeText("Weekly Groceries")
        app.buttons["Create"].tap()
        XCTAssertTrue(
            app.staticTexts["Weekly Groceries"].waitForExistence(timeout: 5),
            "The list should appear immediately after saving."
        )

        // Full relaunch: terminate the process and start it again.
        app.terminate()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Weekly Groceries"].waitForExistence(timeout: 5),
            "The created list should persist across an app relaunch."
        )
    }
}
