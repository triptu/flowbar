import XCTest

/// UI tests for sidebar interactions: selection, rename, context menu, navigation.
///
/// Launches the app once per test with `-uitest-folder` pointing at a temp directory.
/// Tests are consolidated to minimize launch/teardown cycles — each test covers a
/// full user flow rather than a single assertion.
final class SidebarUITests: XCTestCase {

    private var app: XCUIApplication!
    private var tempDir: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false

        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("flowbar-uitest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        for name in ["alpha", "beta", "gamma"] {
            FileManager.default.createFile(
                atPath: tempDir.appendingPathComponent("\(name).md").path,
                contents: "# \(name)".data(using: .utf8)
            )
        }

        app = XCUIApplication()
        app.launchArguments = ["-uitest-folder", tempDir.path]
        app.launch()

        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 5))
    }

    override func tearDownWithError() throws {
        app?.terminate()
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
    }

    // MARK: - Helpers

    private func row(_ id: String) -> XCUIElement { app.groups["sidebar-row-\(id)"] }
    private var renameField: XCUIElement { app.textFields["rename-field"] }
    private var contentTextView: XCUIElement { app.textViews["content-area"] }

    private func enterRename(_ id: String) {
        let r = row(id)
        XCTAssertTrue(r.waitForExistence(timeout: 3))
        r.doubleClick()
        XCTAssertTrue(renameField.waitForExistence(timeout: 2))
    }

    private func typeInRename(_ text: String) {
        renameField.typeKey("a", modifierFlags: .command)
        renameField.typeText(text)
    }

    private func fileExists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("\(name).md").path)
    }

    // MARK: - Tests

    /// Selection + footer navigation in a single launch.
    func testSelectionAndNavigation() {
        // Single-click selects files
        let alpha = row("alpha")
        XCTAssertTrue(alpha.waitForExistence(timeout: 3))
        alpha.click()
        XCTAssertTrue(row("beta").exists)

        // Switch selection
        row("beta").click()
        XCTAssertTrue(alpha.exists, "Previous file should remain visible")

        // Settings toggle: click opens, click again returns to files
        let settingsBtn = app.buttons["sidebar-footer-settings"]
        settingsBtn.click()
        settingsBtn.click()
        XCTAssertTrue(alpha.waitForExistence(timeout: 2), "Files should reappear after settings toggle")

        // Timer toggle
        let timerBtn = app.buttons["sidebar-footer-timer"]
        timerBtn.click()
        timerBtn.click()
        XCTAssertTrue(alpha.waitForExistence(timeout: 2), "Files should reappear after timer toggle")
    }

    /// Full rename keyboard flow: double-click entry, Enter commit, Escape cancel,
    /// re-rename after cancel shows original name, rename persists after double-click
    /// (no single-tap race).
    func testRenameKeyboardFlow() {
        // Double-click enters rename and it persists (no flicker from single-tap race)
        enterRename("alpha")
        XCTAssertTrue(renameField.exists, "Rename field should persist")

        // Enter commits the rename
        typeInRename("New Alpha")
        renameField.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(renameField.waitForNonExistence(timeout: 2))
        XCTAssertTrue(row("new-alpha").waitForExistence(timeout: 2), "File should be renamed")
        XCTAssertFalse(row("alpha").exists)
        XCTAssertTrue(fileExists("new-alpha"), "Renamed file should exist on disk")

        // Escape cancels without renaming
        enterRename("beta")
        typeInRename("Garbage")
        renameField.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(renameField.waitForNonExistence(timeout: 2))
        XCTAssertTrue(row("beta").exists, "File should keep original name after Escape")
        XCTAssertTrue(fileExists("beta"))

        // Re-entering rename after cancel shows the CURRENT name, not the cancelled text
        enterRename("beta")
        let fieldValue = renameField.value as? String ?? ""
        XCTAssertEqual(fieldValue, "Beta", "Should show current name, not previously cancelled text")
        renameField.typeKey(.escape, modifierFlags: [])
    }

    /// Click-outside dismiss: content area commit, sidebar row commit with typed text,
    /// no stuck state, multiple sequential renames.
    func testRenameClickOutsideFlow() {
        // Click content area commits rename
        enterRename("alpha")
        typeInRename("Renamed Alpha")
        contentTextView.click()
        XCTAssertTrue(renameField.waitForNonExistence(timeout: 2))
        XCTAssertTrue(row("renamed-alpha").waitForExistence(timeout: 2))

        // Click different sidebar row commits with the ACTUAL typed text
        enterRename("beta")
        typeInRename("Edited Beta")
        row("gamma").click()
        XCTAssertTrue(renameField.waitForNonExistence(timeout: 2))
        XCTAssertTrue(row("edited-beta").waitForExistence(timeout: 2))

        // No stuck state: can re-enter rename after click-outside dismiss
        enterRename("gamma")
        contentTextView.click()
        XCTAssertTrue(renameField.waitForNonExistence(timeout: 2))
        enterRename("gamma")
        typeInRename("Gamma V2")
        renameField.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(row("gamma-v2").waitForExistence(timeout: 2))

        // Multiple sequential renames all work (renameSessionID resets coordinator)
        enterRename("renamed-alpha")
        typeInRename("File One")
        renameField.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(renameField.waitForNonExistence(timeout: 2))

        enterRename("edited-beta")
        typeInRename("File Two")
        renameField.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(row("file-one").waitForExistence(timeout: 2))
        XCTAssertTrue(row("file-two").exists)
    }

    /// Context menu: rename, new file (enters rename mode), trash.
    func testContextMenu() {
        // Right-click → Rename enters rename mode
        let alpha = row("alpha")
        alpha.rightClick()
        app.menuItems["Rename"].click()
        XCTAssertTrue(renameField.waitForExistence(timeout: 2))
        renameField.typeKey(.escape, modifierFlags: [])

        // Right-click → New File creates untitled and enters rename
        alpha.rightClick()
        app.menuItems["New File"].click()
        XCTAssertTrue(row("untitled").waitForExistence(timeout: 3))
        XCTAssertTrue(renameField.waitForExistence(timeout: 2))
        renameField.typeKey(.escape, modifierFlags: [])

        // Right-click → Move to Trash removes file
        let gamma = row("gamma")
        gamma.rightClick()
        app.menuItems["Move to Trash"].click()
        XCTAssertTrue(gamma.waitForNonExistence(timeout: 3))
        XCTAssertFalse(fileExists("gamma"))
    }

    /// Edge cases: blank name, duplicate name, same name — all no-ops.
    func testRenameEdgeCases() {
        // Blank name is a no-op
        enterRename("alpha")
        typeInRename("   ")
        renameField.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(row("alpha").waitForExistence(timeout: 2), "Blank rename should be no-op")

        // Same name is a no-op
        enterRename("alpha")
        renameField.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(row("alpha").waitForExistence(timeout: 2), "Same-name rename should be no-op")

        // Duplicate name (beta.md already exists) is a no-op
        enterRename("alpha")
        typeInRename("Beta")
        renameField.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(row("alpha").waitForExistence(timeout: 2), "Duplicate rename should be no-op")
        XCTAssertTrue(row("beta").exists, "Existing file should be untouched")
    }
}
