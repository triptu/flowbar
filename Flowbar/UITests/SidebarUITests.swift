import XCTest

/// Smoke test for sidebar interactions. Single app launch covers selection,
/// navigation, rename (commit/cancel/edge cases), context menu, and trash.
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

    private func clickOutsideRename() {
        let win = app.windows.firstMatch
        win.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)).click()
    }

    private func enterRename(_ id: String) {
        let r = row(id)
        XCTAssertTrue(r.waitForExistence(timeout: 3))
        r.rightClick()
        app.menuItems["Rename"].click()
        XCTAssertTrue(renameField.waitForExistence(timeout: 2))
    }

    private func typeInRename(_ text: String) {
        renameField.typeKey("a", modifierFlags: .command)
        renameField.typeText(text)
    }

    private func fileExists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("\(name).md").path)
    }

    // MARK: - Test

    func testSidebarSmoke() {
        let alpha = row("alpha")
        XCTAssertTrue(alpha.waitForExistence(timeout: 3))

        // --- Selection & navigation ---
        alpha.click()
        row("beta").click()
        XCTAssertTrue(alpha.exists)

        let settingsBtn = app.buttons["sidebar-footer-settings"]
        settingsBtn.click(); settingsBtn.click()
        XCTAssertTrue(alpha.waitForExistence(timeout: 2))

        let timerBtn = app.buttons["sidebar-footer-timer"]
        timerBtn.click(); timerBtn.click()
        XCTAssertTrue(alpha.waitForExistence(timeout: 2))

        // --- Rename: Enter commits ---
        enterRename("alpha")
        typeInRename("new-alpha")
        renameField.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(row("new-alpha").waitForExistence(timeout: 2))
        XCTAssertTrue(fileExists("new-alpha"))

        // --- Rename: Escape cancels ---
        enterRename("beta")
        typeInRename("Garbage")
        renameField.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(renameField.waitForNonExistence(timeout: 2))
        XCTAssertTrue(row("beta").exists)

        // --- Rename: click-outside commits ---
        enterRename("beta")
        typeInRename("new-beta")
        clickOutsideRename()
        XCTAssertTrue(row("new-beta").waitForExistence(timeout: 2))

        // --- Rename edge cases: blank and duplicate are no-ops ---
        enterRename("new-alpha")
        typeInRename("   ")
        renameField.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(row("new-alpha").waitForExistence(timeout: 2))

        enterRename("new-alpha")
        typeInRename("new-beta")
        renameField.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(row("new-alpha").waitForExistence(timeout: 2))

        // --- Context menu: new file + trash ---
        row("gamma").rightClick()
        app.menuItems["New File"].click()
        XCTAssertTrue(row("untitled").waitForExistence(timeout: 3))
        renameField.typeKey(.escape, modifierFlags: [])

        row("gamma").rightClick()
        app.menuItems["Move to Trash"].click()
        XCTAssertTrue(row("gamma").waitForNonExistence(timeout: 3))
        XCTAssertFalse(fileExists("gamma"))
    }
}
