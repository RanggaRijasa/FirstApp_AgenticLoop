//
//  GroceryListsRenameUITests.swift
//  CartsyneUITests
//
//  Created by Rangga Rijasa on 19/08/26.
//

import XCTest

/// Focused UI tests for the grocery-list rename flow.
///
/// `testRenameWeeklyGroceriesToHousehold` uses the real on-disk store because
/// it verifies the renamed list survives an app relaunch. The test seeds the
/// list through the UI when the store does not already contain it, so it is
/// deterministic regardless of test order.
final class GroceryListsRenameUITests: XCTestCase {

    @MainActor
    func testRenameWeeklyGroceriesToHousehold() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launch()

        // Seed "Weekly Groceries" through the UI when the store does not
        // already contain it (fresh install or cleared state).
        if !app.staticTexts["Weekly Groceries"].waitForExistence(timeout: 3) {
            app.buttons["Create List"].firstMatch.tap()
            let createField = app.textFields["List name"]
            XCTAssertTrue(createField.waitForExistence(timeout: 5))
            createField.typeText("Weekly Groceries")
            app.buttons["Create"].tap()
            XCTAssertTrue(
                app.staticTexts["Weekly Groceries"].waitForExistence(timeout: 5),
                "The seeded list should appear before it can be renamed."
            )
        }

        // Discover the native row Edit action by swiping the row.
        let row = app.staticTexts["Weekly Groceries"].firstMatch
        row.swipeLeft()
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(
            editButton.waitForExistence(timeout: 3),
            "Swiping a list row should reveal the native Edit action."
        )
        editButton.tap()

        // The edit sheet opens prefilled with the selected list name.
        let nameField = app.textFields["List name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(
            nameField.value as? String,
            "Weekly Groceries",
            "The edit sheet should prefill the selected list's name."
        )

        // Automatic focus: the field is editable without ever tapping it.
        // Clear the prefilled value with delete keys, then type the new name.
        nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 16))
        nameField.typeText("Household")
        app.buttons["Save"].tap()

        // The sheet dismisses and the renamed list appears immediately.
        XCTAssertFalse(
            nameField.waitForExistence(timeout: 2),
            "The edit sheet should dismiss after a successful save."
        )
        XCTAssertTrue(
            app.staticTexts["Household"].waitForExistence(timeout: 5),
            "The renamed list should appear immediately."
        )
        XCTAssertFalse(
            app.staticTexts["Weekly Groceries"].exists,
            "The old name should no longer be shown."
        )

        // Full relaunch: terminate the process and start it again.
        app.terminate()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Household"].waitForExistence(timeout: 5),
            "The renamed list should persist across an app relaunch."
        )
        XCTAssertFalse(
            app.staticTexts["Weekly Groceries"].exists,
            "The old name should not return after relaunch."
        )
    }
}
