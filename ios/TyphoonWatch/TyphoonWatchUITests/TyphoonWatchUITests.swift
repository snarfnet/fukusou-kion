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

        let trackMap = app.otherElements["typhoonTrackMap"].firstMatch
        scrollUntilVisible(trackMap, in: app)
        XCTAssertTrue(trackMap.isHittable, "Track map should be reachable in the compact scrolling layout.")

        let firstFeed = app.links["dataFeed-0"].firstMatch
        scrollUntilVisible(firstFeed, in: app)
        XCTAssertTrue(firstFeed.isHittable, "First data source link should be reachable and tappable on compact iPhone.")
    }

    private func scrollUntilVisible(_ element: XCUIElement, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<6 where !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(element.exists, "Expected element to exist after scrolling.", file: file, line: line)
    }
}
