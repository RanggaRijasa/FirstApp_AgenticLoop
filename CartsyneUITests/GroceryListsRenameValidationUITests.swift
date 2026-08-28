//
//  GroceryListsRenameValidationUITests.swift
//  CartsyneUITests
//
//  Created by Rangga Rijasa on 19/08/26.
//

import XCTest

/// UI tests for rename validation, accessibility, and Dynamic Type behavior
/// that the core rename flow test does not exercise.
final class GroceryListsRenameValidationUITests: XCTestCase {

    /// A rejected whitespace-only save must keep the sheet open, show a
    /// friendly message, and retain the typed value so the user can correct
    /// it; retrying with a valid name then succeeds and trims the input.
    @MainActor
    func testRenameRejectsWhitespaceOnlyNameAndAllowsRetry() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments += ["-uiTestInMemoryStore"]
        app.launch()

        // Seed the list through the create flow.
        app.buttons["Create List"].firstMatch.tap()
        let createField = app.textFields["List name"]
        XCTAssertTrue(createField.waitForExistence(timeout: 5))
        createField.typeText("Weekly Groceries")
        app.buttons["Create"].tap()
        XCTAssertTrue(app.staticTexts["Weekly Groceries"].waitForExistence(timeout: 5))

        // Open the edit sheet via the native row Edit action.
        let row = app.staticTexts["Weekly Groceries"].firstMatch
        row.swipeLeft()
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()
        let nameField = app.textFields["List name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))

        // Replace the prefilled name with whitespace only.
        nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 16))
        nameField.typeText("   ")
        app.buttons["Save"].tap()

        // Rejected: the sheet stays open, the message is understandable (not
        // a raw Swift error), and the typed value is retained for correction.
        XCTAssertTrue(
            nameField.waitForExistence(timeout: 3),
            "The edit sheet should stay open after a rejected save."
        )
        XCTAssertTrue(
            app.staticTexts["Enter a list name."].exists,
            "A rejected save should show the friendly validation message."
        )
        // Capture the rejected state with the friendly error for review.
        let errorScreenshot = XCUIScreen.main.screenshot()
        let errorAttachment = XCTAttachment(screenshot: errorScreenshot)
        errorAttachment.name = "EditListSheet-WhitespaceRejected"
        errorAttachment.lifetime = .keepAlways
        add(errorAttachment)

        // Retry with a valid name: leading whitespace is trimmed and the
        // rename completes.
        nameField.typeText("Household")
        app.buttons["Save"].tap()

        XCTAssertFalse(
            nameField.waitForExistence(timeout: 2),
            "The edit sheet should dismiss after a successful save."
        )
        XCTAssertTrue(
            app.staticTexts["Household"].waitForExistence(timeout: 5),
            "The retried rename should appear immediately."
        )
        XCTAssertFalse(app.staticTexts["Weekly Groceries"].exists)
    }

    /// Edit controls must carry meaningful VoiceOver labels and the whole
    /// rename flow must remain usable at the largest accessibility content
    /// size.
    @MainActor
    func testRenameSheetVoiceOverLabelsAndLargeDynamicType() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments += ["-uiTestInMemoryStore"]
        // Largest supported Dynamic Type size.
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()

        app.buttons["Create List"].firstMatch.tap()
        let createField = app.textFields["List name"]
        XCTAssertTrue(createField.waitForExistence(timeout: 5))
        XCTAssertEqual(
            createField.label,
            "List name",
            "The name field should carry a meaningful VoiceOver label."
        )
        createField.typeText("Weekly Groceries")
        app.buttons["Create"].tap()
        XCTAssertTrue(app.staticTexts["Weekly Groceries"].waitForExistence(timeout: 5))

        let row = app.staticTexts["Weekly Groceries"].firstMatch
        row.swipeLeft()
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        XCTAssertEqual(
            editButton.label,
            "Edit",
            "The native row Edit action should carry a meaningful VoiceOver label."
        )
        editButton.tap()

        let nameField = app.textFields["List name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.label, "List name")
        XCTAssertTrue(app.buttons["Save"].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)

        // Capture the sheet at the largest Dynamic Type size for review.
        let sheetScreenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: sheetScreenshot)
        attachment.name = "EditListSheet-AccessibilityXXXL"
        attachment.lifetime = .keepAlways
        add(attachment)

        // The full flow still works at the largest size.
        nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 16))
        nameField.typeText("Household")
        app.buttons["Save"].tap()

        XCTAssertTrue(
            app.staticTexts["Household"].waitForExistence(timeout: 5),
            "The rename should complete at the largest Dynamic Type size."
        )
    }
}
