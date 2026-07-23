import XCTest
@testable import MoriGo

final class MoriGoTests: XCTestCase {
    func testBundledGameContainsRequiredResources() throws {
        let bundle = Bundle.main
        let htmlURL = try XCTUnwrap(bundle.url(forResource: "index", withExtension: "html", subdirectory: "Web"))
        let web = htmlURL.deletingLastPathComponent()
        XCTAssertTrue(FileManager.default.fileExists(atPath: web.appendingPathComponent("app.js").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: web.appendingPathComponent("style.css").path))
        for name in ["hamster", "rabbit", "meerkat", "marmot", "sage"] {
            let image = web.appendingPathComponent("assets/characters/\(name).png")
            XCTAssertTrue(FileManager.default.fileExists(atPath: image.path), "\(name).png is missing")
        }
    }

    func testGameIncludesBeginnerFeatures() throws {
        let bundle = Bundle.main
        let url = try XCTUnwrap(bundle.url(forResource: "app", withExtension: "js", subdirectory: "Web"))
        let script = try String(contentsOf: url, encoding: .utf8)
        for feature in ["bestHint", "scoreGame", "finishGame", "tryMove"] {
            XCTAssertTrue(script.contains(feature), "\(feature) is missing")
        }
    }
}
