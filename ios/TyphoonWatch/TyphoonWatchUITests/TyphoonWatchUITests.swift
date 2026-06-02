import XCTest

final class TyphoonWatchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCompactHomeContentIsVisible() throws {
        let app = XCUIApplication()
        app.launch()

        let title = app.staticTexts["台風を観測"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 10), "Home title should exist on compact iPhone.")
        XCTAssertTrue(title.isHittable, "Home title should be visible in the compact viewport.")

        let refreshButton = app.buttons["最新データを取得"].firstMatch
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 5), "Refresh button should exist on compact iPhone.")
        XCTAssertTrue(refreshButton.isHittable, "Refresh button should be visible and tappable on compact iPhone.")
    }
}
