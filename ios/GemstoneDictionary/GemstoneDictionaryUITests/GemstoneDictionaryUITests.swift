import XCTest

final class GemstoneDictionaryUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDictionarySearchTaFindsTurquoise() throws {
        let app = launchApp(initialTab: 1, useTaQuery: true)

        XCTAssertTrue(findStaticText("ターコイズ", in: app))
    }

    func testDictionarySearchJadeFindsJadeite() throws {
        let app = launchApp(initialTab: 1, dictionaryQuery: "jade")

        XCTAssertTrue(app.staticTexts["翡翠"].waitForExistence(timeout: 8))
    }

    func testSupplementalCatalogSearchFindsDanburite() throws {
        let app = launchApp(initialTab: 1, dictionaryQuery: "danburite")

        XCTAssertTrue(app.staticTexts["ダンビュライト"].waitForExistence(timeout: 8))
    }

    func testMarketListAndDemoSampleAreReachable() throws {
        let app = launchApp(initialTab: 2)
        XCTAssertTrue(app.descendants(matching: .any)["marketPriceList"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "155")).firstMatch.waitForExistence(timeout: 8))

        app.terminate()
        app.launchEnvironment["UITEST_INITIAL_TAB"] = "0"
        app.launch()
        let sampleButton = app.descendants(matching: .any)["demoSample-jadeite"]
        XCTAssertTrue(sampleButton.waitForExistence(timeout: 8))
        sampleButton.tap()
        XCTAssertTrue(app.staticTexts["翡翠"].waitForExistence(timeout: 8))
        XCTAssertTrue(findStaticTextContaining("市場価格", in: app))
        XCTAssertTrue(findStaticTextContaining("サイズ信頼度", in: app))
        XCTAssertTrue(findStaticTextContaining("見かけサイズ", in: app))
    }

    private func launchApp(initialTab: Int = 0, dictionaryQuery: String? = nil, useTaQuery: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST_INITIAL_TAB"] = "\(initialTab)"
        if useTaQuery {
            app.launchEnvironment["UITEST_DICTIONARY_QUERY_TA"] = "1"
        }
        if let dictionaryQuery {
            app.launchEnvironment["UITEST_DICTIONARY_QUERY"] = dictionaryQuery
        }
        app.launch()
        return app
    }

    private func findStaticText(_ label: String, in app: XCUIApplication) -> Bool {
        let text = app.staticTexts[label]
        if text.waitForExistence(timeout: 4) {
            return true
        }
        for _ in 0..<8 {
            app.swipeUp()
            if text.waitForExistence(timeout: 2) {
                return true
            }
        }
        return false
    }

    private func findStaticTextContaining(_ label: String, in app: XCUIApplication) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", label)
        let text = app.staticTexts.containing(predicate).firstMatch
        if text.waitForExistence(timeout: 4) {
            return true
        }
        for _ in 0..<10 {
            app.swipeUp()
            if text.waitForExistence(timeout: 2) {
                return true
            }
        }
        return false
    }
}
