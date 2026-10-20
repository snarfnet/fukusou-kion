import XCTest
import UIKit
import CoreText
import AVFoundation
import ImageIO
@testable import TYPO

final class TYPOTests: XCTestCase {
    @MainActor
    func testMaterialSelectionReflectsSelectedGlyphs() {
        var artwork = Artwork()
        artwork.text = "AB"
        let model = StudioModel(artwork)
        model.select(1)
        model.applySurface(.bronze)
        XCTAssertEqual(model.selectedSurface, .bronze)
        XCTAssertEqual(model.artwork.surface, .chrome)
        model.select(0, additive: true)
        XCTAssertNil(model.selectedSurface, "A mixed selection must not highlight the global material")
        model.selection = []
        XCTAssertEqual(model.selectedSurface, .chrome)
    }

    @MainActor
    func testSelectionRemainsValidAcrossTextHistory() {
        var artwork = Artwork()
        artwork.text = "AB"
        let model = StudioModel(artwork)
        model.edit { $0.replaceText("A") }
        model.undo()
        model.select(1)
        model.redo()
        XCTAssertTrue(model.selection.isEmpty)
        XCTAssertEqual(model.artwork.text, "A")
    }

    func testInputLimits() {
        for text in ["永", "A", "8", "O", "タイポ", "TYPO 2026", "A\nB"] {
            XCTAssertNil(InputCheck.validate(text))
        }
        for text in ["", "   ", "😀", "A\nB\nC\nD", String(repeating: "A", count: 13)] {
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
            XCTAssertFalse(try GlyphMeshBuilder.build(artwork).childNodes.isEmpty)
        }
        let o = try GlyphOutlineBuilder.build(text: "O", spacing: 0)
        let box = o.boundingBoxOfPath
        XCTAssertFalse(o.contains(CGPoint(x: box.midX, y: box.midY), using: .evenOdd))
    }

    func testMultilineGlyphIdentityAndAlignment() throws {
        let glyphs = try GlyphOutlineBuilder.glyphs(text: "永A\n O", spacing: 3, layout: Composition())
        XCTAssertEqual(glyphs.map(\.index), [0, 1, 4])
        XCTAssertGreaterThan(glyphs[0].path.boundingBoxOfPath.midY, glyphs[2].path.boundingBoxOfPath.midY)
        var layout = Composition()
        layout.alignment = .trailing
        let aligned = try GlyphOutlineBuilder.glyphs(text: "AA\nA", spacing: 0, layout: layout)
        XCTAssertEqual(aligned[1].path.boundingBoxOfPath.maxX, aligned[2].path.boundingBoxOfPath.maxX, accuracy: 0.01)
    }

    func testPerGlyphEditsAndGrouping() throws {
        var artwork = Artwork()
        artwork.text = "ABC"
        artwork.group([0, 1])
        XCTAssertEqual(artwork.expandedSelection([0]), [0, 1])
        artwork.updateGlyph(at: 0) { $0.surface = .bronze; $0.x = 20 }
        let saved = try JSONDecoder().decode(Artwork.self, from: JSONEncoder().encode(artwork))
        XCTAssertEqual(saved.adjustment(at: 0).surface, .bronze)
        XCTAssertEqual(saved.adjustment(at: 0).x, 20)
        XCTAssertNil(saved.adjustment(at: 2).group)
        artwork.ungroup([0])
        XCTAssertEqual(artwork.expandedSelection([0]), [0])
        artwork.replaceText("永")
        XCTAssertTrue(artwork.glyphs.isEmpty)
    }

    @MainActor
    func testPresetRenderContactSheet() throws {
        let presets = ArtworkPreset.allCases
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        var images: [UIImage] = []
        for preset in presets {
            var artwork = Artwork()
            preset.apply(to: &artwork)
            images.append(try SculptureRenderer().image(artwork, size: CGSize(width: 256, height: 256), transparent: false))
        }
        let sheet = UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 512), format: format).image { _ in
            for (index, image) in images.enumerated() {
                image.draw(in: CGRect(x: (index % 4) * 256, y: (index / 4) * 256, width: 256, height: 256))
            }
        }
        let attachment = XCTAttachment(image: sheet)
        attachment.name = "Eight material presets"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testImageEncodersAndMovieDuration() async throws {
        let artwork = Artwork()
        for format in ImageFormat.allCases where format.supported {
            let url = try await ExportService.image(artwork, size: CGSize(width: 128, height: 128), format: format, transparent: true)
            defer { try? FileManager.default.removeItem(at: url) }
            let data = try Data(contentsOf: url)
            XCTAssertNotNil(UIImage(data: data), format.rawValue)
        }
        var progresses: [Double] = []
        let url = try await ExportService.movie(artwork, size: CGSize(width: 256, height: 256), seconds: 1, fps: 3) { progresses.append($0) }
        defer { try? FileManager.default.removeItem(at: url) }
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        XCTAssertEqual(CMTimeGetSeconds(duration), 1, accuracy: 0.05)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        XCTAssertEqual(tracks.count, 1)
        let dimensions = try await XCTUnwrap(tracks.first).load(.naturalSize)
        XCTAssertEqual(dimensions.width, 256)
        XCTAssertEqual(progresses.last, 1)
    }

    @MainActor
    func testExportCancellation() async throws {
        let task = Task { @MainActor in
            try await ExportService.movie(Artwork(), size: CGSize(width: 128, height: 128), seconds: 5) { _ in }
        }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Cancelled export must not complete")
        } catch is CancellationError {}
    }

    @MainActor
    func testSupportedExportDimensions() async throws {
        for size in [CGSize(width: 1080, height: 1080), CGSize(width: 2160, height: 2160),
                     CGSize(width: 1080, height: 1920), CGSize(width: 2480, height: 3508),
                     CGSize(width: 3840, height: 2160)] {
            let url = try await ExportService.image(Artwork(), size: size, format: .png, transparent: true)
            defer { try? FileManager.default.removeItem(at: url) }
            let source = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
            let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any])
            XCTAssertEqual(properties[kCGImagePropertyPixelWidth as String] as? Int, Int(size.width))
            XCTAssertEqual(properties[kCGImagePropertyPixelHeight as String] as? Int, Int(size.height))
        }
    }

    @MainActor
    func testFullVideoDurations() async throws {
        for seconds in [5, 10, 15] {
            let url = try await ExportService.movie(Artwork(), size: CGSize(width: 128, height: 128), seconds: seconds) { _ in }
            defer { try? FileManager.default.removeItem(at: url) }
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            XCTAssertEqual(CMTimeGetSeconds(duration), Double(seconds), accuracy: 0.04)
        }
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

    @MainActor
    func testExtrudedCountersSurviveImageRendering() throws {
        for (letter, expected) in [("A", 1), ("8", 2), ("O", 1)] {
            var artwork = Artwork()
            artwork.text = letter; artwork.yaw = 0; artwork.pitch = 0; artwork.bevel = 0
            artwork.surface = .paper
            let image = try SculptureRenderer().image(artwork, size: CGSize(width: 160, height: 160), transparent: true)
            let cg = try XCTUnwrap(image.cgImage)
            let width = cg.width, height = cg.height
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            try bytes.withUnsafeMutableBytes { buffer in
                let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: width, height: height,
                    bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
            var visited = Set<Int>(), enclosed = 0
            for seed in 0..<(width * height) where !visited.contains(seed) && bytes[seed * 4 + 3] < 128 {
                var queue = [seed], cursor = 0, border = false
                visited.insert(seed)
                while cursor < queue.count {
                    let pixel = queue[cursor]; cursor += 1
                    let x = pixel % width, y = pixel / width
                    if x == 0 || y == 0 || x == width - 1 || y == height - 1 { border = true }
                    for (dx, dy) in [(1,0),(-1,0),(0,1),(0,-1)] {
                        let nx = x + dx, ny = y + dy
                        guard nx >= 0, ny >= 0, nx < width, ny < height else { continue }
                        let next = ny * width + nx
                        if bytes[next * 4 + 3] < 128 && visited.insert(next).inserted { queue.append(next) }
                    }
                }
                if !border && queue.count > 3 { enclosed += 1 }
            }
            XCTAssertEqual(enclosed, expected, "\(letter) must preserve its counters in the actual mesh render")
            let attachment = XCTAttachment(image: image)
            attachment.name = "Counter validation \(letter)"; attachment.lifetime = .keepAlways; add(attachment)
        }
    }
}
