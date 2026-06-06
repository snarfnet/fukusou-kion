import XCTest

final class ShokuninSumahoDXUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainToolsAreVisibleAndTappable() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["職人スマホDX"].waitForExistence(timeout: 8))

        let tabBar = app.scrollViews["tool-tabs"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        for toolID in ["angle", "level", "convert", "slope", "material", "checklist", "photo", "center-guide", "notes"] {
            tapTab(toolID, app: app, tabBar: tabBar)
            XCTAssertTrue(
                app.scrollViews["tool-content-\(toolID)"].waitForExistence(timeout: 3),
                "\(toolID) content should be visible after tapping"
            )
        }
    }

    func testPrimaryActionsStayReachableOnCompactScreens() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["職人スマホDX"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["保存"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["保存"].firstMatch.tap()

        let tabBar = app.scrollViews["tool-tabs"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tapTab("level", app: app, tabBar: tabBar)
        XCTAssertTrue(app.buttons["測定を保存"].firstMatch.waitForExistence(timeout: 4))
    }

    private func tapTab(_ toolID: String, app: XCUIApplication, tabBar: XCUIElement) {
        let button = app.buttons["tool-tab-\(toolID)"].firstMatch
        for _ in 0..<10 {
            if button.exists, button.frame.intersects(tabBar.frame), button.frame.width > 1 {
                button.tap()
                return
            }
            tabBar.swipeLeft()
        }
        XCTFail("\(toolID) tab should be visible and tappable")
    }
}
