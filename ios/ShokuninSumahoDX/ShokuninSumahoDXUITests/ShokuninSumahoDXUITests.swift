import XCTest

final class ShokuninSumahoDXUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainToolsAreVisibleAndTappable() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["職人スマホDX"].waitForExistence(timeout: 8))

        let expectedTitles = [
            "角度": "角度計DX",
            "水平": "2軸水平器",
            "変換": "単位変換DX",
            "勾配": "勾配計算",
            "材料": "材料計算",
            "点検": "現場チェックリスト",
            "写真": "写真に測定値を重ねる",
            "中心線": "中心線ガイド",
            "履歴": "測定履歴とPDF"
        ]
        let tabBar = app.scrollViews["tool-tabs"]
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        let tools = ["角度", "水平", "変換", "勾配", "材料", "点検", "写真", "中心線", "履歴"]
        for tool in tools {
            tapTab(tool, app: app, tabBar: tabBar)
            XCTAssertTrue(app.staticTexts[expectedTitles[tool] ?? tool].waitForExistence(timeout: 3), "\(tool) content should be visible after tapping")
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
        let horizontalButton = app.buttons["水平"].firstMatch
        if !horizontalButton.isHittable {
            tabBar.swipeRight()
        }
        XCTAssertTrue(horizontalButton.waitForExistence(timeout: 3))
        XCTAssertTrue(horizontalButton.isHittable)
        horizontalButton.tap()
        XCTAssertTrue(app.buttons["測定を保存"].firstMatch.waitForExistence(timeout: 4))
    }

    private func tapTab(_ title: String, app: XCUIApplication, tabBar: XCUIElement) {
        for _ in 0..<8 {
            let button = app.buttons[title].firstMatch
            if button.exists, isFullyVisible(button, inside: tabBar) {
                button.tap()
                return
            }
            tabBar.swipeLeft()
        }
        XCTFail("\(title) tab should be visible and tappable")
    }

    private func isFullyVisible(_ element: XCUIElement, inside container: XCUIElement) -> Bool {
        guard element.exists, container.exists else { return false }
        let frame = element.frame
        let containerFrame = container.frame
        guard frame.width > 1, frame.height > 1 else { return false }
        return frame.minX >= containerFrame.minX &&
            frame.maxX <= containerFrame.maxX
    }
}
