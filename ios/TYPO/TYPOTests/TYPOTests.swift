import XCTest
import UIKit
import CoreText
@testable import TYPO

final class TYPOTests: XCTestCase {
    func testInputLimits() {
        for text in ["永", "A", "8", "O", "タイポ", "TYPO 2026"] {
            XCTAssertNil(InputCheck.validate(text))
        }
        for text in ["", "   ", "😀", "A\nB", String(repeating: "A", count: 13)] {
            XCTAssertNotNil(InputCheck.validate(text))
        }
    }

    func testHistoryRoundTripAndBound() throws {
        var history = EditHistory()
        var artwork = Artwork()
        for index in 0..<70 {
            history.record(artwork)
            artwork.depth = Double(index)
        }
        XCTAssertEqual(history.past.count, 60)
        let beforeUndo = artwork
        artwork = try XCTUnwrap(history.undo(artwork))
        XCTAssertEqual(history.redo(artwork), beforeUndo)
        let encoded = try JSONEncoder().encode(history)
        XCTAssertEqual(try JSONDecoder().decode(EditHistory.self, from: encoded).past.count, 60)
        history.record(artwork)
        XCTAssertTrue(history.future.isEmpty)
    }

    func testGlyphOutlinesAndCounters() throws {
        for text in ["永", "A", "8", "O"] {
            let path = try GlyphOutlineBuilder.build(text: text, spacing: 0)
            XCTAssertFalse(path.isEmpty)
            XCTAssertGreaterThan(path.boundingBoxOfPath.width, 0)
            var artwork = Artwork()
            artwork.text = text
            XCTAssertNotNil(try GlyphMeshBuilder.build(artwork).geometry)
        }
        let o = try GlyphOutlineBuilder.build(text: "O", spacing: 0)
        let box = o.boundingBoxOfPath
        XCTAssertFalse(o.contains(CGPoint(x: box.midX, y: box.midY), using: .evenOdd))
    }

    @MainActor
    func testAtomicPersistenceAndCorruptionIsolation() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = ProjectStore(folder: folder)
        var artwork = Artwork()
        artwork.text = "永"
        var history = EditHistory()
        history.record(artwork)
        artwork.surface = .bronze
        try store.save(artwork, history: history)
        let reopened = ProjectStore(folder: folder)
        XCTAssertEqual(reopened.projects.count, 1)
        XCTAssertEqual(try reopened.load(artwork).history.past.count, 1)
        XCTAssertEqual(try reopened.load(artwork).artwork.surface, .bronze)
        try Data("broken".utf8).write(to: folder.appendingPathComponent("broken.json"))
        try reopened.reload()
        XCTAssertEqual(reopened.projects.count, 1)
        XCTAssertNotNil(reopened.issue)
        try reopened.delete(artwork)
        XCTAssertTrue(reopened.projects.isEmpty)
    }

    @MainActor
    func testTransparentPNGExport() throws {
        let renderer = SculptureRenderer()
        let image = try renderer.image(Artwork(), size: CGSize(width: 256, height: 256), transparent: true)
        XCTAssertEqual(image.cgImage?.width, 256)
        XCTAssertEqual(image.cgImage?.height, 256)
        let decoded = try XCTUnwrap(UIImage(data: XCTUnwrap(image.pngData())))
        let cg = try XCTUnwrap(decoded.cgImage)
        var bytes = [UInt8](repeating: 0, count: 256 * 256 * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: 256, height: 256, bitsPerComponent: 8,
                                                bytesPerRow: 256 * 4, space: CGColorSpaceCreateDeviceRGB(),
                                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(cg, in: CGRect(x: 0, y: 0, width: 256, height: 256))
        }
        XCTAssertEqual(bytes[3], 0, "The corner must remain transparent")
        XCTAssertTrue(stride(from: 3, to: bytes.count, by: 4).contains { bytes[$0] > 0 }, "The sculpture must be visible")
    }
}
