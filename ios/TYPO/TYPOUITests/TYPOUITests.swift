import XCTest

final class TYPOUITests: XCTestCase {
    @MainActor
    func testCreateEditRotateSaveReopenAndExport() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        let start = Date()
        let create = app.buttons["home.create"]
        XCTAssertTrue(create.waitForExistence(timeout: 15))
        create.tap()
        let open = app.buttons["new.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        app.buttons["A"].tap()
        open.tap()
        let save = app.buttons["studio.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 15))
        XCTAssertLessThan(Date().timeIntervalSince(start), 60)
        app.buttons["Bronze"].tap()
        XCTAssertTrue(app.buttons["studio.undo"].isEnabled)
        capture("Studio portrait")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        capture("Studio landscape")
        XCUIDevice.shared.orientation = .portrait
        save.tap()
        app.buttons["studio.close"].tap()
        let gallery = app.buttons["home.gallery"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 10))
        if !gallery.isHittable { app.swipeUp() }
        gallery.tap()
        let project = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "gallery.project.")).firstMatch
        XCTAssertTrue(project.waitForExistence(timeout: 10))
        capture("Gallery")
        project.tap()
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["studio.undo"].isEnabled, "History should survive reopening")
        let workTab = app.buttons["studio.tab.作品"]
        for _ in 0..<3 {
            if workTab.isHittable { break }
            app.scrollViews["studio.tabs"].swipeLeft()
        }
        workTab.tap()
        app.buttons["studio.export"].tap()
        XCTAssertTrue(app.navigationBars["書き出し"].waitForExistence(timeout: 5))
        capture("Export options")
        app.buttons["完了"].tap()
        app.buttons["studio.close"].tap()
        app.terminate()
        app.launch()
        if !app.buttons["home.gallery"].isHittable { app.swipeUp() }
        app.buttons["home.gallery"].tap()
        XCTAssertTrue(project.waitForExistence(timeout: 10), "Project should survive process restart")
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
