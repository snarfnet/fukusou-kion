import XCTest

final class SukebanMahjongUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testTitleStartsFirstTutorial() {
        let app = launchApp(skipOnboarding: false)

        XCTAssertTrue(app.staticTexts["title.logo"].waitForExistence(timeout: 5))
        let start = app.buttons["title.start"]
        XCTAssertTrue(start.exists)
        start.tap()

        let tutorialPage = app.staticTexts["tutorial.page"]
        XCTAssertTrue(tutorialPage.waitForExistence(timeout: 3))
        XCTAssertEqual(tutorialPage.label, "遊び方　1/5")
    }

    func testContinueRouteOpensFirstOpponentStory() {
        let app = launchApp(skipOnboarding: true)

        let start = app.buttons["title.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        XCTAssertTrue(app.staticTexts["map.title"].waitForExistence(timeout: 3))
        let firstOpponent = app.buttons["map.school.1"]
        XCTAssertTrue(firstOpponent.exists)
        firstOpponent.tap()

        XCTAssertTrue(app.staticTexts["profile.name"].waitForExistence(timeout: 3))
        let challenge = app.buttons["profile.challenge"]
        XCTAssertTrue(challenge.exists)
        challenge.tap()

        XCTAssertTrue(app.buttons["dialogue.next"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["dialogue.chapter"].label, "第7章　吹雪の番長")
    }

    func testNationwideRosterOpensHundredthCharacter() {
        let app = launchApp(skipOnboarding: true)

        let castButton = app.buttons["title.cast"]
        XCTAssertTrue(castButton.waitForExistence(timeout: 5))
        castButton.tap()

        XCTAssertTrue(app.staticTexts["cast.title"].waitForExistence(timeout: 3))
        app.buttons["cast.jump.last"].tap()
        let hundredth = app.buttons["cast.character.99"]
        XCTAssertTrue(hundredth.waitForExistence(timeout: 5))
        hundredth.tap()

        XCTAssertTrue(app.staticTexts["cast.profile.name"].waitForExistence(timeout: 3))
        let profile = app.scrollViews.firstMatch
        assertExistsAfterScrolling(
            app.otherElements["cast.profile.favoriteFood"],
            in: profile
        )
        assertExistsAfterScrolling(
            app.otherElements["cast.profile.favoriteType"],
            in: profile
        )
        assertExistsAfterScrolling(
            app.otherElements["cast.profile.favoriteMotorcycle"],
            in: profile
        )
        assertExistsAfterScrolling(
            app.otherElements["cast.profile.favoriteCar"],
            in: profile
        )
    }

    func testStoryArchiveOpensFirstOfSixtySixChapters() {
        let app = launchApp(skipOnboarding: true)

        let archive = app.buttons["title.chapters"]
        XCTAssertTrue(archive.waitForExistence(timeout: 5))
        archive.tap()

        XCTAssertTrue(app.staticTexts["chapters.title"].waitForExistence(timeout: 3))
        let firstChapter = app.buttons["chapters.chapter.1"]
        XCTAssertTrue(firstChapter.exists)
        firstChapter.tap()

        XCTAssertEqual(
            app.staticTexts["dialogue.chapter"].label,
            "第1章　赤紙"
        )
    }

    private func launchApp(skipOnboarding: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["SUKEBAN_UI_TEST_RESET"] = "1"
        if skipOnboarding {
            app.launchEnvironment["SUKEBAN_UI_TEST_SKIP_ONBOARDING"] = "1"
        }
        app.launch()
        return app
    }

    private func assertExistsAfterScrolling(
        _ element: XCUIElement,
        in scrollView: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0..<20 where !element.exists {
            scrollView.swipeUp()
        }
        XCTAssertTrue(element.waitForExistence(timeout: 2), file: file, line: line)
    }
}
