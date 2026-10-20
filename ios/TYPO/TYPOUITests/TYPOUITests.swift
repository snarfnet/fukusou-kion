import XCTest
import UIKit

final class TYPOUITests: XCTestCase {
    @MainActor
    func testEnglishHome() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let create = app.buttons["home.create"]
        XCTAssertTrue(create.waitForExistence(timeout: 15))
        XCTAssertTrue(create.label.contains("Create"), "English resources must ship inside the app")
        capture("English home")
    }

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
        save.tap()
        XCTAssertLessThan(Date().timeIntervalSince(start), 60, "First saved artwork should take less than a minute")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        let landscape = NSPredicate { _, _ in app.frame.width > app.frame.height }
        expectation(for: landscape, evaluatedWith: nil)
        waitForExpectations(timeout: 10)
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
            let tabs = app.scrollViews["studio.tabs"]
            // Scroll the visible tab row, below the navigation bar's safe-area extension.
            tabs.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.85))
                .press(forDuration: 0.05, thenDragTo: tabs.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.85)))
        }
        workTab.tap()
        app.buttons["studio.export"].tap()
        XCTAssertTrue(app.navigationBars["書き出し"].waitForExistence(timeout: 5))
        capture("Export options")
        app.buttons["export.share"].tap()
        let shareSheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 30), "The rendered image should reach the system share sheet")
        // Dismiss without sending the generated image anywhere.
        if UIDevice.current.userInterfaceIdiom == .pad {
            capture("Image share sheet")
            shareSheet.swipeDown()
            let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in !shareSheet.exists }, object: nil)
            if XCTWaiter.wait(for: [dismissed], timeout: 3) != .completed {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
                    .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)))
            }
        } else {
            let closeShare = app.buttons["header.closeButton"]
            expectation(for: NSPredicate { _, _ in closeShare.isHittable }, evaluatedWith: nil)
            waitForExpectations(timeout: 15)
            capture("Image share sheet")
            closeShare.tap()
        }
        expectation(for: NSPredicate { _, _ in !shareSheet.exists }, evaluatedWith: nil)
        waitForExpectations(timeout: 10)
        app.buttons["完了"].tap()
        expectation(for: NSPredicate { _, _ in app.buttons["studio.exhibit"].isHittable }, evaluatedWith: nil)
        waitForExpectations(timeout: 10)
        app.buttons["studio.exhibit"].tap()
        expectation(for: NSPredicate { _, _ in !save.exists }, evaluatedWith: nil)
        waitForExpectations(timeout: 10)
        capture("Exhibition")
        // The permanent gesture remains available after exhibition controls fade away.
        app.otherElements["studio.viewport"].doubleTap()
        XCTAssertTrue(save.waitForExistence(timeout: 10))
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
