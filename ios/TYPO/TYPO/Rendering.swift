import SwiftUI
import SceneKit
import CoreText

enum GeometryError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case let .invalid(message) = self { return L10n.text(message) }; return nil }
}

struct GlyphOutline {
    let index: Int
    let path: CGPath
}

final class GlyphNode: SCNNode {
    var glyphIndex = 0
    var basePosition = SCNVector3Zero
    var arcAngle: Float = 0

    override init() { super.init() }
    required init?(coder: NSCoder) { super.init(coder: coder) }

    func apply(_ adjustment: GlyphAdjustment) {
        position = SCNVector3(basePosition.x + Float(adjustment.x), basePosition.y + Float(adjustment.y),
                             Float(adjustment.z + Double(adjustment.layer) * 2))
        eulerAngles = SCNVector3(Float(adjustment.rotationX), Float(adjustment.rotationY), Float(adjustment.rotationZ) + arcAngle)
        scale = SCNVector3(Float(adjustment.scale), Float(adjustment.scale), Float(adjustment.scale))
        renderingOrder = adjustment.layer
    }
}

enum GlyphOutlineBuilder {
    static func build(text: String, spacing: Double) throws -> CGPath {
        let result = CGMutablePath()
        for glyph in try glyphs(text: text, spacing: spacing, layout: Composition()) {
            result.addPath(glyph.path)
        }
        return result
    }

    static func glyphs(text: String, spacing: Double, layout: Composition) throws -> [GlyphOutline] {
        if let error = InputCheck.validate(text) { throw GeometryError.invalid(error) }
        guard UIFont(name: "NotoSerifCJKjp-Regular", size: 100) != nil else {
            throw GeometryError.invalid("同梱フォントを読み込めません。アプリを再インストールしてください。")
        }
        let font = CTFontCreateWithName("NotoSerifCJKjp-Regular" as CFString, 100, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            .kern: spacing, .ligature: 0
        ]
        let rows = text.components(separatedBy: "\n")
        let lines = rows.map { CTLineCreateWithAttributedString(NSAttributedString(string: $0, attributes: attributes)) }
        let widths = lines.map { CTLineGetTypographicBounds($0, nil, nil, nil) }
        let maximumWidth = widths.max() ?? 0
        var result: [GlyphOutline] = []
        var characterOffset = 0
        var segments = 0
        for (row, line) in lines.enumerated() {
            let characters = Array(rows[row])
            var utf16ToCharacter: [Int: Int] = [:]
            var offset = 0
            for (index, character) in characters.enumerated() {
                for location in offset..<(offset + String(character).utf16.count) { utf16ToCharacter[location] = index }
                offset += String(character).utf16.count
            }
            let shift: Double
            switch layout.alignment {
            case .leading: shift = 0
            case .center: shift = (maximumWidth - widths[row]) / 2
            case .trailing: shift = maximumWidth - widths[row]
            }
            var paths: [Int: CGMutablePath] = [:]
            for run in CTLineGetGlyphRuns(line) as! [CTRun] {
                let count = CTRunGetGlyphCount(run)
                var glyphs = [CGGlyph](repeating: 0, count: count)
                var positions = [CGPoint](repeating: .zero, count: count)
                var indices = [CFIndex](repeating: 0, count: count)
                CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
                CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
                CTRunGetStringIndices(run, CFRange(location: 0, length: 0), &indices)
                let attrs = CTRunGetAttributes(run) as NSDictionary
                let runFont = attrs[kCTFontAttributeName] as! CTFont
                for i in 0..<count {
                    guard let index = utf16ToCharacter[indices[i]] else { throw GeometryError.invalid("文字の位置を取得できませんでした。") }
                    guard glyphs[i] != 0 else { throw GeometryError.invalid(L10n.format("「%@」の字形がありません。", String(characters[index]))) }
                    if let path = CTFontCreatePathForGlyph(runFont, glyphs[i], nil) {
                        path.applyWithBlock { _ in segments += 1 }
                        let combined = paths[index] ?? CGMutablePath()
                        combined.addPath(path, transform: CGAffineTransform(translationX: positions[i].x + shift,
                                                                            y: positions[i].y - Double(row) * 100 * layout.lineHeight))
                        paths[index] = combined
                    } else if !characters[index].isWhitespace {
                        throw GeometryError.invalid(L10n.format("「%@」の輪郭を作れませんでした。", String(characters[index])))
                    }
                }
            }
            for index in paths.keys.sorted() {
                if let path = paths[index] { result.append(GlyphOutline(index: characterOffset + index, path: path)) }
            }
            characterOffset += characters.count + 1
        }
        guard !result.isEmpty else { throw GeometryError.invalid("表示できる文字を入力してください。") }
        guard segments < 30000 else { throw GeometryError.invalid("字形が複雑すぎます。文字数を減らしてください。") }
        return result
    }
}

enum GlyphMeshBuilder {
    static func build(_ artwork: Artwork) throws -> SCNNode {
        let outlines = try GlyphOutlineBuilder.glyphs(text: artwork.text, spacing: artwork.spacing, layout: artwork.layout)
        let bounds = outlines.reduce(CGRect.null) { $0.union($1.path.boundingBoxOfPath) }
        let root = SCNNode()
        for outline in outlines {
            let box = outline.path.boundingBoxOfPath
            var center = CGAffineTransform(translationX: -box.midX, y: -box.midY)
            guard let local = outline.path.copy(using: &center) else { throw GeometryError.invalid("字形の配置に失敗しました。") }
            let path = UIBezierPath(cgPath: local)
            path.flatness = CGFloat(artwork.layout.smoothness)
            let shape = SCNShape(path: path, extrusionDepth: CGFloat(max(0, artwork.depth)))
            shape.chamferRadius = CGFloat(min(artwork.bevel, artwork.depth / 2))
            let adjustment = artwork.adjustment(at: outline.index)
            shape.materials = [material(adjustment.surface ?? artwork.surface, finish: artwork.finish)]
            let node = GlyphNode()
            node.geometry = shape
            node.glyphIndex = outline.index
            node.name = "glyph:\(outline.index)"
            let unit = bounds.width > 0 ? (box.midX - bounds.midX) / bounds.width : 0
            let arc = artwork.layout.arc * unit
            let lift = sin(abs(arc)) * abs(box.midX - bounds.midX) * (artwork.layout.arc < 0 ? -1 : 1)
            node.basePosition = SCNVector3(Float(box.midX - bounds.midX), Float(box.midY - bounds.midY + lift), 0)
            node.arcAngle = Float(arc)
            node.apply(adjustment)
            root.addChildNode(node)
        }
        return root
    }

    static func material(_ surface: Surface, finish: MaterialSettings) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = surface.color
        material.metalness.contents = surface == .chrome || surface == .bronze ? finish.metallic : 0.0
        material.roughness.contents = surface == .paper ? max(0.65, finish.roughness) : finish.roughness
        material.clearCoat.contents = finish.clearCoat
        material.clearCoatRoughness.contents = 0.12
        if finish.scratches > 0 {
            material.normal.contents = scratches()
            material.normal.intensity = CGFloat(finish.scratches * 0.35)
            material.normal.wrapS = .repeat
            material.normal.wrapT = .repeat
        }
        if surface == .glass {
            material.transparency = 0.32
            material.transparencyMode = .dualLayer
            material.isDoubleSided = true
            material.roughness.contents = 0.08
            material.fresnelExponent = 2
            material.clearCoat.contents = 1.0
        }
        if surface == .neon { material.emission.contents = UIColor(red: 0.35, green: 0.8, blue: 1, alpha: 1) }
        return material
    }

    private static func scratches() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { context in
            UIColor(red: 0.5, green: 0.5, blue: 1, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 256, height: 256))
            for i in 0..<90 {
                let x = (i * 73) % 256, y = (i * 131) % 256
                UIColor(red: 0.6, green: 0.4, blue: 1, alpha: 0.45).setStroke()
                context.cgContext.setLineWidth(0.5)
                context.cgContext.move(to: CGPoint(x: x, y: y))
                context.cgContext.addLine(to: CGPoint(x: x + 20 + i % 45, y: y + 3))
                context.cgContext.strokePath()
            }
        }
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
    private let stage = SCNNode()
    private let sculpture = SCNNode()
    private var last: Artwork?
    private var modelWidth: Float = 100
    private var modelHeight: Float = 100
    private var lights: [SCNNode] = []
    private let floor = SCNNode()

    init() {
        camera.camera = SCNCamera()
        camera.camera?.usesOrthographicProjection = true
        camera.camera?.zFar = 5000
        camera.position = SCNVector3(0, 0, 500)
        scene.rootNode.addChildNode(camera)
        scene.rootNode.addChildNode(stage)
        stage.addChildNode(sculpture)
        let floorGeometry = SCNFloor()
        floorGeometry.reflectivity = 0
        let floorMaterial = SCNMaterial()
        floorMaterial.lightingModel = .physicallyBased
        floorMaterial.roughness.contents = 0.9
        floorGeometry.materials = [floorMaterial]
        floor.geometry = floorGeometry
        floor.position.y = -65
        stage.addChildNode(floor)
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
        let shadowLight = lights[0]
        shadowLight.light?.type = .directional
        shadowLight.look(at: SCNVector3(0, 0, 0))
        shadowLight.light?.castsShadow = true
        shadowLight.light?.shadowMode = .deferred
        shadowLight.light?.shadowRadius = 8
        shadowLight.light?.shadowSampleCount = 16
        shadowLight.light?.shadowColor = UIColor.black.withAlphaComponent(0.35)
        shadowLight.light?.orthographicScale = 900
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
            || last?.spacing != artwork.spacing
            || last?.layout.arc != artwork.layout.arc || last?.layout.alignment != artwork.layout.alignment
            || last?.layout.lineHeight != artwork.layout.lineHeight || last?.layout.smoothness != artwork.layout.smoothness {
            let node = try GlyphMeshBuilder.build(artwork)
            let bounds = node.boundingBox
            modelWidth = bounds.max.x - bounds.min.x
            modelHeight = bounds.max.y - bounds.min.y
            sculpture.childNodes.forEach { $0.removeFromParentNode() }
            sculpture.addChildNode(node)
        }
        // Camera, light, material, and per-letter transforms reuse the existing meshes.
        for root in sculpture.childNodes {
            for case let node as GlyphNode in root.childNodes {
                node.apply(artwork.adjustment(at: node.glyphIndex))
                if last?.surface != artwork.surface || last?.finish != artwork.finish
                    || last?.adjustment(at: node.glyphIndex).surface != artwork.adjustment(at: node.glyphIndex).surface {
                    node.geometry?.materials = [GlyphMeshBuilder.material(artwork.adjustment(at: node.glyphIndex).surface ?? artwork.surface,
                                                                         finish: artwork.finish)]
                }
            }
        }
        stage.eulerAngles = SCNVector3(Float(artwork.pitch), Float(artwork.yaw), Float(artwork.layout.roll))
        stage.position = SCNVector3(Float(artwork.panX), Float(artwork.panY), 0)
        camera.camera?.orthographicScale = Double(max(85, modelHeight * 0.72, modelWidth / Float(max(aspect, 0.2)) * 0.72)) / artwork.zoom
        lights[0].light?.intensity = CGFloat(1400 * artwork.light)
        lights[1].light?.intensity = CGFloat(1200 * artwork.lighting.fill)
        lights[2].light?.intensity = CGFloat(1500 * artwork.lighting.rim)
        let temperature = artwork.lighting.temperature
        lights[0].light?.temperature = CGFloat(6500 - temperature * 2500)
        switch artwork.lighting.style {
        case .gallery:
            lights[0].position = SCNVector3(-150, 200, 250)
            lights[0].light?.shadowRadius = 8
        case .daylight:
            lights[0].position = SCNVector3(150, 300, 160)
            lights[0].light?.shadowRadius = 12
        case .dramatic:
            lights[0].position = SCNVector3(-250, 120, 80)
            lights[0].light?.shadowRadius = 3
            lights[1].light?.intensity = CGFloat(150 * artwork.lighting.fill)
        }
        lights[0].look(at: SCNVector3(0, 0, 0))
        if last?.backdrop != artwork.backdrop {
            scene.background.contents = background(artwork.backdrop)
            floor.geometry?.firstMaterial?.diffuse.contents = artwork.backdrop == .obsidian ? UIColor(white: 0.043, alpha: 1)
                : artwork.backdrop == .concrete ? UIColor(white: 0.32, alpha: 1) : UIColor(white: 0.94, alpha: 1)
            floor.geometry?.firstMaterial?.roughness.contents = 0.9
        }
        floor.position.y = -max(65, modelHeight * 0.6)
        floor.isHidden = artwork.backdrop == .obsidian || artwork.backdrop == .gradient
        last = artwork
    }

    private func background(_ backdrop: Backdrop) -> Any {
        switch backdrop {
        case .obsidian: return UIColor(red: 0.043, green: 0.043, blue: 0.051, alpha: 1)
        case .ivory: return UIColor(red: 0.95, green: 0.94, blue: 0.92, alpha: 1)
        case .concrete: return UIColor(white: 0.32, alpha: 1)
        case .frosted, .gradient:
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            return UIGraphicsImageRenderer(size: CGSize(width: 32, height: 512), format: format).image { context in
                let colors = backdrop == .frosted
                    ? [UIColor(white: 0.97, alpha: 1).cgColor, UIColor(red: 0.74, green: 0.81, blue: 0.85, alpha: 1).cgColor]
                    : [UIColor(red: 0.12, green: 0.17, blue: 0.23, alpha: 1).cgColor, UIColor(red: 0.45, green: 0.50, blue: 0.56, alpha: 1).cgColor]
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
                    context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 512), options: [])
                }
            }
        }
    }

    func exhibition(at time: Double, artwork: Artwork) {
        stage.eulerAngles.y = Float(artwork.yaw + time * 0.06)
        lights[0].light?.intensity = CGFloat(1400 * artwork.light * (1 + sin(time * 0.25) * 0.06))
    }

    func select(_ indices: Set<Int>) {
        for root in sculpture.childNodes {
            for node in root.childNodes {
                node.childNode(withName: "selection", recursively: false)?.removeFromParentNode()
                guard let name = node.name, let index = Int(name.replacingOccurrences(of: "glyph:", with: "")),
                      indices.contains(index) else { continue }
                let bounds = node.boundingBox
                let box = SCNBox(width: CGFloat(bounds.max.x - bounds.min.x + 4),
                                 height: CGFloat(bounds.max.y - bounds.min.y + 4),
                                 length: CGFloat(bounds.max.z - bounds.min.z + 4), chamferRadius: 0)
                let material = SCNMaterial()
                material.lightingModel = .constant
                material.diffuse.contents = UIColor(red: 0.77, green: 0.65, blue: 0.47, alpha: 1)
                material.fillMode = .lines
                box.materials = [material]
                let marker = SCNNode(geometry: box)
                marker.name = "selection"
                marker.position = SCNVector3((bounds.max.x + bounds.min.x) / 2, (bounds.max.y + bounds.min.y) / 2, 0)
                node.addChildNode(marker)
            }
        }
    }

    func setLowPower(_ enabled: Bool) {
        lights[0].light?.shadowMapSize = enabled ? CGSize(width: 512, height: 512) : CGSize(width: 2048, height: 2048)
        lights[0].light?.shadowSampleCount = enabled ? 4 : 16
    }

    func image(_ artwork: Artwork, size: CGSize, transparent: Bool) throws -> UIImage {
        let isolated = SculptureRenderer()
        try isolated.update(artwork, aspect: size.width / size.height)
        return isolated.snapshotRenderer(transparent: transparent).snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
    }

    func snapshotRenderer(transparent: Bool = false) -> SCNRenderer {
        if transparent {
            scene.background.contents = UIColor.clear
            floor.isHidden = true
        }
        let renderer = SCNRenderer(device: nil, options: nil)
        renderer.scene = scene
        renderer.pointOfView = camera
        return renderer
    }
}

struct SculptureView: UIViewRepresentable {
    @ObservedObject var renderer: SculptureRenderer
    var lowPower: Bool
    var interaction: (SculptureInteraction) -> Void = { _ in }
    func makeCoordinator() -> Coordinator { Coordinator(interaction: interaction) }
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = renderer.scene
        view.pointOfView = renderer.camera
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.isAccessibilityElement = true
        view.accessibilityLabel = L10n.text("文字の立体作品。下の構図パネルでも角度を調整できます。")
        context.coordinator.install(on: view)
        return view
    }
    func updateUIView(_ view: SCNView, context: Context) {
        view.preferredFramesPerSecond = lowPower ? 30 : 60
        view.antialiasingMode = lowPower ? .none : .multisampling4X
        view.setNeedsDisplay()
        context.coordinator.interaction = interaction
        renderer.setLowPower(lowPower)
    }

    final class Coordinator: NSObject {
        var interaction: (SculptureInteraction) -> Void
        init(interaction: @escaping (SculptureInteraction) -> Void) { self.interaction = interaction }
        func install(on view: SCNView) {
            let rotate = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
            rotate.minimumNumberOfTouches = 1; rotate.maximumNumberOfTouches = 1
            view.addGestureRecognizer(rotate)
            let move = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
            move.minimumNumberOfTouches = 2; move.maximumNumberOfTouches = 2
            view.addGestureRecognizer(move)
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinch(_:)))
            view.addGestureRecognizer(pinch)
            let select = UILongPressGestureRecognizer(target: self, action: #selector(selectGlyph(_:)))
            view.addGestureRecognizer(select)
            let reset = UITapGestureRecognizer(target: self, action: #selector(reset(_:)))
            reset.numberOfTapsRequired = 2
            view.addGestureRecognizer(reset)
            let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
            tap.require(toFail: reset)
            view.addGestureRecognizer(tap)
        }
        @objc private func pan(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .began { interaction(.begin) }
            if gesture.state == .changed {
                let translation = gesture.translation(in: gesture.view)
                interaction(gesture.minimumNumberOfTouches == 2 ? .move(translation) : .rotate(translation))
            }
            if [.ended, .cancelled, .failed].contains(gesture.state) { interaction(.end) }
        }
        @objc private func pinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .began { interaction(.begin) }
            if gesture.state == .changed { interaction(.zoom(gesture.scale)) }
            if [.ended, .cancelled, .failed].contains(gesture.state) { interaction(.end) }
        }
        @objc private func selectGlyph(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began, let view = gesture.view as? SCNView else { return }
            for hit in view.hitTest(gesture.location(in: view), options: nil) {
                var node: SCNNode? = hit.node
                while let current = node {
                    if let name = current.name, name.hasPrefix("glyph:"), let index = Int(name.dropFirst(6)) {
                        interaction(.select(index)); return
                    }
                    node = current.parent
                }
            }
        }
        @objc private func reset(_ gesture: UITapGestureRecognizer) { interaction(.reset) }
        @objc private func tap(_ gesture: UITapGestureRecognizer) { interaction(.tap) }
    }
}

enum SculptureInteraction {
    case begin, end, rotate(CGPoint), move(CGPoint), zoom(CGFloat), select(Int), reset, tap
}
