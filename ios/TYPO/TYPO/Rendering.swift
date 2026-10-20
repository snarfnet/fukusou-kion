import SwiftUI
import SceneKit
import CoreText

enum GeometryError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case let .invalid(message) = self { return message }; return nil }
}

enum GlyphOutlineBuilder {
    static func build(text: String, spacing: Double) throws -> CGPath {
        if let error = InputCheck.validate(text) { throw GeometryError.invalid(error) }
        guard UIFont(name: "NotoSerifCJKjp-Regular", size: 100) != nil else {
            throw GeometryError.invalid("同梱フォントを読み込めません。アプリを再インストールしてください。")
        }
        let font = CTFontCreateWithName("NotoSerifCJKjp-Regular" as CFString, 100, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            .kern: spacing
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        let result = CGMutablePath()
        for run in CTLineGetGlyphRuns(line) as! [CTRun] {
            let count = CTRunGetGlyphCount(run)
            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
            let attrs = CTRunGetAttributes(run) as NSDictionary
            let runFont = attrs[kCTFontAttributeName] as! CTFont
            for i in 0..<count {
                guard glyphs[i] != 0 else { throw GeometryError.invalid("この文字の字形がありません。別の文字を入力してください。") }
                if let path = CTFontCreatePathForGlyph(runFont, glyphs[i], nil) {
                    result.addPath(path, transform: CGAffineTransform(translationX: positions[i].x, y: positions[i].y))
                } else {
                    // Spaces have advance but intentionally no outline.
                    var advance = CGSize.zero
                    var glyph = glyphs[i]
                    CTFontGetAdvancesForGlyphs(runFont, .horizontal, &glyph, &advance, 1)
                    var space: UniChar = 32
                    var spaceGlyph: CGGlyph = 0
                    CTFontGetGlyphsForCharacters(runFont, &space, &spaceGlyph, 1)
                    var fullSpace: UniChar = 0x3000
                    var fullSpaceGlyph: CGGlyph = 0
                    CTFontGetGlyphsForCharacters(runFont, &fullSpace, &fullSpaceGlyph, 1)
                    guard glyph == spaceGlyph || glyph == fullSpaceGlyph else {
                        throw GeometryError.invalid("輪郭を作れない文字が含まれています。")
                    }
                }
            }
        }
        guard !result.isEmpty else { throw GeometryError.invalid("表示できる文字を入力してください。") }
        var segments = 0
        result.applyWithBlock { _ in segments += 1 }
        guard segments < 30000 else { throw GeometryError.invalid("字形が複雑すぎます。文字数を減らしてください。") }
        return result
    }
}

enum GlyphMeshBuilder {
    static func build(_ artwork: Artwork) throws -> SCNNode {
        let path = try GlyphOutlineBuilder.build(text: artwork.text, spacing: artwork.spacing)
        let shape = SCNShape(path: UIBezierPath(cgPath: path), extrusionDepth: CGFloat(max(0, artwork.depth)))
        shape.chamferRadius = CGFloat(min(artwork.bevel, artwork.depth / 2, 5))
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = artwork.surface.color
        material.metalness.contents = artwork.surface == .chrome || artwork.surface == .bronze ? 0.95 : 0.0
        material.roughness.contents = artwork.surface == .paper ? 0.85 : 0.22
        if artwork.surface == .glass {
            material.transparency = 0.48
            material.isDoubleSided = true
            material.roughness.contents = 0.08
        }
        if artwork.surface == .neon { material.emission.contents = UIColor(red: 0.35, green: 0.8, blue: 1, alpha: 1) }
        shape.materials = [material]
        let node = SCNNode(geometry: shape)
        let bounds = path.boundingBoxOfPath
        node.position = SCNVector3(-Float(bounds.midX), -Float(bounds.midY), 0)
        return node
    }
}

extension Surface {
    var color: UIColor {
        switch self {
        case .chrome: return UIColor(red: 0.72, green: 0.76, blue: 0.81, alpha: 1)
        case .bronze: return UIColor(red: 0.66, green: 0.40, blue: 0.19, alpha: 1)
        case .glass: return UIColor(red: 0.66, green: 0.85, blue: 0.93, alpha: 1)
        case .paper: return UIColor(red: 0.95, green: 0.92, blue: 0.84, alpha: 1)
        case .monolith: return UIColor(white: 0.15, alpha: 1)
        case .neon: return UIColor(red: 0.3, green: 0.8, blue: 1, alpha: 1)
        }
    }
}

@MainActor
final class SculptureRenderer: ObservableObject {
    let scene = SCNScene()
    let camera = SCNNode()
    private let sculpture = SCNNode()
    private var last: Artwork?
    private var modelWidth: Float = 100
    private var lights: [SCNNode] = []

    init() {
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.zFar = 5000
        camera.position = SCNVector3(0, 0, 500)
        scene.rootNode.addChildNode(camera)
        scene.rootNode.addChildNode(sculpture)
        for (position, intensity, color) in [
            (SCNVector3(-150, 200, 250), 1400.0, UIColor.white),
            (SCNVector3(180, 50, 100), 900.0, UIColor(red: 0.68, green: 0.78, blue: 1, alpha: 1)),
            (SCNVector3(30, 160, -100), 1800.0, UIColor(red: 1, green: 0.85, blue: 0.65, alpha: 1))
        ] {
            let node = SCNNode()
            node.light = SCNLight()
            node.light?.type = .omni
            node.light?.intensity = CGFloat(intensity)
            node.light?.color = color
            node.position = position
            scene.rootNode.addChildNode(node)
            lights.append(node)
        }
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 220
        scene.rootNode.addChildNode(ambient)
        scene.lightingEnvironment.contents = Self.environment()
        scene.lightingEnvironment.intensity = 1.3
    }

    private static func environment() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 512), format: format).image { context in
            UIColor(white: 0.12, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1024, height: 512))
            UIColor(white: 0.95, alpha: 1).setFill()
            context.fill(CGRect(x: 110, y: 40, width: 150, height: 400))
            UIColor(white: 0.65, alpha: 1).setFill()
            context.fill(CGRect(x: 600, y: 90, width: 300, height: 100))
        }
    }

    func update(_ artwork: Artwork, aspect: Double = 1) throws {
        if last?.text != artwork.text || last?.depth != artwork.depth || last?.bevel != artwork.bevel
            || last?.spacing != artwork.spacing || last?.surface != artwork.surface {
            let node = try GlyphMeshBuilder.build(artwork)
            let bounds = node.boundingBox
            modelWidth = bounds.max.x - bounds.min.x
            sculpture.childNodes.forEach { $0.removeFromParentNode() }
            sculpture.addChildNode(node)
        }
        sculpture.eulerAngles = SCNVector3(Float(artwork.pitch), Float(artwork.yaw), 0)
        sculpture.position = SCNVector3(Float(artwork.panX), Float(artwork.panY), 0)
        camera.camera?.orthographicScale = Double(max(85, modelWidth / Float(max(aspect, 0.2)) * 0.72)) / artwork.zoom
        lights[0].light?.intensity = CGFloat(1400 * artwork.light)
        scene.background.contents = artwork.backdrop == .obsidian ? UIColor(red: 0.043, green: 0.043, blue: 0.051, alpha: 1)
            : artwork.backdrop == .ivory ? UIColor(red: 0.95, green: 0.94, blue: 0.92, alpha: 1)
            : UIColor(white: 0.32, alpha: 1)
        last = artwork
    }

    func image(_ artwork: Artwork, size: CGSize, transparent: Bool) throws -> UIImage {
        let isolated = SculptureRenderer()
        try isolated.update(artwork, aspect: size.width / size.height)
        if transparent { isolated.scene.background.contents = UIColor.clear }
        let renderer = SCNRenderer(device: nil, options: nil)
        renderer.scene = isolated.scene
        renderer.pointOfView = isolated.camera
        return renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
    }
}

struct SculptureView: UIViewRepresentable {
    @ObservedObject var renderer: SculptureRenderer
    var lowPower: Bool
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = renderer.scene
        view.pointOfView = renderer.camera
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.isAccessibilityElement = true
        view.accessibilityLabel = "文字の立体作品。下の構図パネルでも角度を調整できます。"
        return view
    }
    func updateUIView(_ view: SCNView, context: Context) {
        view.preferredFramesPerSecond = lowPower ? 30 : 60
        view.antialiasingMode = lowPower ? .none : .multisampling4X
        view.setNeedsDisplay()
    }
}
