import CoreGraphics
import Foundation

enum StitchPlanner {
    static func plan(elements: [DesignElement], size: CGSize, palette: [EmbroideryColor]) -> StitchPlan {
        var blocksByColor: [String: StitchBlockBuilder] = [:]

        for element in elements {
            switch element {
            case .vine(let vine):
                appendPolyline(vine.points, color: vine.color, to: &blocksByColor)
            case .leaf(let leaf):
                appendLeaf(leaf, to: &blocksByColor)
            case .flower(let flower):
                appendFlower(flower, to: &blocksByColor)
            case .berry(let berry):
                appendBerry(berry, to: &blocksByColor)
            case .importedVector(let vector):
                appendImportedVector(vector, to: &blocksByColor)
            case .bird(let bird):
                appendBird(bird, to: &blocksByColor)
            case .curl(let curl):
                appendPolyline(curlPoints(curl), color: curl.color, to: &blocksByColor)
            }
        }

        let blocks = blocksByColor.values
            .sorted { $0.color.name < $1.color.name }
            .map { StitchBlock(color: $0.color, points: $0.points) }
        return StitchPlan(colors: palette, blocks: blocks)
    }

    private static func appendLeaf(_ leaf: LeafElement, to builders: inout [String: StitchBlockBuilder]) {
        let outline = leafOutline(leaf, steps: 28)
        appendPolyline(outline + [outline[0]], color: leaf.color, to: &builders)
        appendPolyline([leafTip(leaf, direction: -1), leafTip(leaf, direction: 1)], color: leaf.veinColor, to: &builders)
    }

    private static func appendFlower(_ flower: FlowerElement, to builders: inout [String: StitchBlockBuilder]) {
        for outline in flowerPetalOutlines(flower, steps: 22) {
            appendClosed(outline, color: flower.fill, to: &builders)
        }
        for accent in flowerAccentLines(flower) {
            appendPolyline(accent, color: flower.centerColor, to: &builders)
        }
        let centerRadius = flowerCenterRadius(flower)
        if centerRadius > 0 {
            appendCircle(center: flower.center, radius: centerRadius, color: flower.centerColor, to: &builders)
        }
    }

    private static func appendBerry(_ berry: BerryElement, to builders: inout [String: StitchBlockBuilder]) {
        for outline in berryOutlines(berry, steps: 20) {
            appendClosed(outline, color: berry.color, to: &builders)
        }
        for accent in berryAccentLines(berry) {
            appendPolyline(accent, color: berry.color, to: &builders)
        }
    }

    private static func appendImportedVector(_ vector: ImportedVectorElement, to builders: inout [String: StitchBlockBuilder]) {
        for outline in importedVectorOutlines(vector) {
            appendClosed(outline, color: vector.color, to: &builders)
        }
    }

    private static func appendBird(_ bird: BirdElement, to builders: inout [String: StitchBlockBuilder]) {
        for outline in birdBodyOutlines(bird) {
            appendClosed(outline, color: bird.bodyColor, to: &builders)
        }
        for outline in birdWingOutlines(bird) {
            appendClosed(outline, color: bird.wingColor, to: &builders)
        }
        for line in birdAccentLines(bird) {
            appendPolyline(line, color: bird.accentColor, to: &builders)
        }
    }

    private static func appendCircle(center: CGPoint, radius: CGFloat, color: EmbroideryColor, to builders: inout [String: StitchBlockBuilder]) {
        let points = (0...24).map { index in
            let angle = (CGFloat(index) / 24.0) * CGFloat.pi * 2.0
            return CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
        }
        appendPolyline(points, color: color, to: &builders)
    }

    private static func appendClosed(_ points: [CGPoint], color: EmbroideryColor, to builders: inout [String: StitchBlockBuilder]) {
        guard let first = points.first else { return }
        appendPolyline(points + [first], color: color, to: &builders)
    }

    private static func appendPolyline(_ points: [CGPoint], color: EmbroideryColor, to builders: inout [String: StitchBlockBuilder]) {
        guard points.count > 1 else { return }
        var builder = builders[color.hex] ?? StitchBlockBuilder(color: color, points: [])
        if let first = points.first {
            builder.points.append(StitchPoint(x: Double(first.x), y: Double(first.y), jump: true))
        }
        for pair in zip(points.dropLast(), points.dropFirst()) {
            let distance = hypot(pair.1.x - pair.0.x, pair.1.y - pair.0.y)
            let steps = max(2, Int((distance / 5.0).rounded(.up)))
            for step in 1...steps {
                let t = CGFloat(step) / CGFloat(steps)
                let x = pair.0.x + (pair.1.x - pair.0.x) * t
                let y = pair.0.y + (pair.1.y - pair.0.y) * t
                builder.points.append(StitchPoint(x: Double(x), y: Double(y), jump: false))
            }
        }
        builders[color.hex] = builder
    }

    static func leafOutline(_ leaf: LeafElement, steps: Int) -> [CGPoint] {
        (0..<steps).map { index in
            let t = (CGFloat(index) / CGFloat(steps)) * CGFloat.pi * 2.0
            let pinch = CGFloat(pow(Double(abs(sin(t))), 0.58))
            let x = cos(t) * leaf.size.width * 0.5 * pinch
            let y = sin(t) * leaf.size.height * 0.5
            return rotate(CGPoint(x: x, y: y), by: leaf.angle, around: leaf.center)
        }
    }

    static func leafTip(_ leaf: LeafElement, direction: CGFloat) -> CGPoint {
        rotate(CGPoint(x: 0, y: direction * leaf.size.height * 0.5), by: leaf.angle, around: leaf.center)
    }

    static func rotatedOval(center: CGPoint, width: CGFloat, height: CGFloat, angle: CGFloat, steps: Int) -> [CGPoint] {
        (0..<steps).map { index in
            let t = (CGFloat(index) / CGFloat(steps)) * CGFloat.pi * 2.0
            let point = CGPoint(x: cos(t) * width * 0.5, y: sin(t) * height * 0.5)
            return rotate(point, by: angle, around: center)
        }
    }

    static func flowerPetalOutlines(_ flower: FlowerElement, steps: Int = 24) -> [[CGPoint]] {
        switch flower.kind {
        case .daisy:
            return radialOvals(flower, width: 0.62, height: 1.18, reach: 0.58, steps: steps)
        case .forgetMeNot:
            return radialOvals(flower, width: 0.82, height: 0.9, reach: 0.46, steps: steps)
        case .poppy:
            return radialOvals(flower, width: 1.05, height: 1.18, reach: 0.45, steps: steps)
        case .tulip:
            return (-1...1).map { index in
                let angle = flower.angle - CGFloat.pi / 2 + CGFloat(index) * 0.34
                let center = CGPoint(
                    x: flower.center.x + cos(angle) * flower.radius * 0.24,
                    y: flower.center.y + sin(angle) * flower.radius * 0.24
                )
                return teardrop(center: center, width: flower.radius * 0.72, height: flower.radius * 1.35, angle: angle, steps: steps)
            }
        case .rose:
            return (0..<flower.petals).map { index in
                let progress = CGFloat(index) / CGFloat(max(1, flower.petals - 1))
                let angle = flower.angle + progress * CGFloat.pi * 2.4
                let scale = 0.28 + progress * 0.86
                return rotatedOval(
                    center: flower.center,
                    width: flower.radius * scale,
                    height: flower.radius * (0.32 + progress * 0.42),
                    angle: angle,
                    steps: max(14, steps - 4)
                )
            }
        case .bell:
            return (0..<flower.petals).map { index in
                let spread = (CGFloat(index) - CGFloat(flower.petals - 1) / 2) * 0.32
                let angle = flower.angle + CGFloat.pi / 2 + spread
                let center = CGPoint(
                    x: flower.center.x + cos(angle) * flower.radius * 0.45,
                    y: flower.center.y + sin(angle) * flower.radius * 0.45
                )
                return teardrop(center: center, width: flower.radius * 0.58, height: flower.radius * 1.04, angle: angle, steps: steps)
            }
        case .clover:
            return radialOvals(flower, width: 0.88, height: 0.96, reach: 0.42, steps: steps)
        case .starflower:
            return (0..<flower.petals).map { petal in
                let angle = flower.angle + (CGFloat(petal) / CGFloat(flower.petals)) * CGFloat.pi * 2
                return pointedPetal(center: flower.center, radius: flower.radius, angle: angle)
            }
        case .lavender:
            return (0..<flower.petals).map { index in
                let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
                let progress = CGFloat(index) / CGFloat(max(1, flower.petals - 1))
                let along = (progress - 0.5) * flower.radius * 1.65
                let stemAngle = flower.angle - CGFloat.pi / 2
                let local = CGPoint(x: side * flower.radius * 0.18, y: along)
                let center = rotate(local, by: stemAngle, around: flower.center)
                return rotatedOval(center: center, width: flower.radius * 0.34, height: flower.radius * 0.54, angle: stemAngle + side * 0.75, steps: 14)
            }
        case .bud:
            return (0..<flower.petals).map { index in
                let angle = flower.angle - CGFloat.pi / 2 + (CGFloat(index) - CGFloat(flower.petals - 1) / 2) * 0.3
                return teardrop(center: flower.center, width: flower.radius * 0.48, height: flower.radius * 0.96, angle: angle, steps: steps)
            }
        case .cosmos:
            return radialOvals(flower, width: 0.48, height: 1.28, reach: 0.6, steps: steps)
        case .anemone:
            return radialOvals(flower, width: 0.78, height: 1.08, reach: 0.52, steps: steps)
        }
    }

    static func flowerAccentLines(_ flower: FlowerElement) -> [[CGPoint]] {
        switch flower.kind {
        case .rose:
            let steps = 28
            let spiral = (0...steps).map { index in
                let t = CGFloat(index) / CGFloat(steps)
                let angle = flower.angle + t * CGFloat.pi * 4.6
                let radius = flower.radius * (0.12 + t * 0.58)
                return CGPoint(x: flower.center.x + cos(angle) * radius, y: flower.center.y + sin(angle) * radius)
            }
            return [spiral]
        case .lavender:
            let stemAngle = flower.angle - CGFloat.pi / 2
            let a = rotate(CGPoint(x: 0, y: -flower.radius * 0.95), by: stemAngle, around: flower.center)
            let b = rotate(CGPoint(x: 0, y: flower.radius * 0.95), by: stemAngle, around: flower.center)
            return [[a, b]]
        case .tulip, .bud, .bell:
            return (0..<max(2, min(4, flower.petals))).map { index in
                let offset = CGFloat(index) - CGFloat(max(2, min(4, flower.petals)) - 1) / 2
                let angle = flower.angle - CGFloat.pi / 2 + offset * 0.18
                return [
                    flower.center,
                    CGPoint(x: flower.center.x + cos(angle) * flower.radius * 0.74, y: flower.center.y + sin(angle) * flower.radius * 0.74)
                ]
            }
        default:
            return []
        }
    }

    static func flowerCenterRadius(_ flower: FlowerElement) -> CGFloat {
        switch flower.kind {
        case .lavender, .bud:
            return 0
        case .rose:
            return flower.radius * 0.1
        case .anemone:
            return flower.radius * 0.32
        case .poppy:
            return flower.radius * 0.28
        default:
            return flower.radius * 0.22
        }
    }

    static func berryOutlines(_ berry: BerryElement, steps: Int = 20) -> [[CGPoint]] {
        switch berry.kind {
        case .round:
            return [rotatedOval(center: berry.center, width: berry.radius * 2, height: berry.radius * 2, angle: berry.angle, steps: steps)]
        case .ovalBud:
            return [rotatedOval(center: berry.center, width: berry.radius * 1.35, height: berry.radius * 2.35, angle: berry.angle, steps: steps)]
        case .teardrop:
            return [teardrop(center: berry.center, width: berry.radius * 1.5, height: berry.radius * 2.35, angle: berry.angle, steps: steps)]
        case .twinCherry:
            return [-0.48, 0.48].map { offset in
                let center = rotate(CGPoint(x: CGFloat(offset) * berry.radius, y: berry.radius * 0.12), by: berry.angle, around: berry.center)
                return rotatedOval(center: center, width: berry.radius * 1.28, height: berry.radius * 1.28, angle: berry.angle, steps: steps)
            }
        case .beadCluster:
            return (0..<5).map { index in
                let angle = berry.angle + CGFloat(index) / 5 * CGFloat.pi * 2
                let distance = index == 0 ? CGFloat(0) : berry.radius * 0.72
                let center = CGPoint(x: berry.center.x + cos(angle) * distance, y: berry.center.y + sin(angle) * distance)
                return rotatedOval(center: center, width: berry.radius * 0.9, height: berry.radius * 0.9, angle: angle, steps: 14)
            }
        case .wheat:
            return (0..<6).map { index in
                let side: CGFloat = index.isMultiple(of: 2) ? -1 : 1
                let progress = CGFloat(index) / 5
                let local = CGPoint(x: side * berry.radius * 0.36, y: (progress - 0.5) * berry.radius * 2.4)
                let center = rotate(local, by: berry.angle, around: berry.center)
                return rotatedOval(center: center, width: berry.radius * 0.55, height: berry.radius * 1.05, angle: berry.angle + side * 0.58, steps: 12)
            }
        case .seedPod:
            return [rotatedOval(center: berry.center, width: berry.radius * 1.15, height: berry.radius * 2.8, angle: berry.angle, steps: steps)]
        case .roseHip:
            return [rotatedOval(center: berry.center, width: berry.radius * 1.55, height: berry.radius * 2.05, angle: berry.angle, steps: steps)]
        }
    }

    static func berryAccentLines(_ berry: BerryElement) -> [[CGPoint]] {
        switch berry.kind {
        case .twinCherry:
            let top = rotate(CGPoint(x: 0, y: -berry.radius * 1.35), by: berry.angle, around: berry.center)
            return [-0.48, 0.48].map { offset in
                let bottom = rotate(CGPoint(x: CGFloat(offset) * berry.radius, y: berry.radius * -0.15), by: berry.angle, around: berry.center)
                return [top, bottom]
            }
        case .wheat, .seedPod:
            let a = rotate(CGPoint(x: 0, y: -berry.radius * 1.45), by: berry.angle, around: berry.center)
            let b = rotate(CGPoint(x: 0, y: berry.radius * 1.45), by: berry.angle, around: berry.center)
            return [[a, b]]
        case .roseHip:
            let cap = rotate(CGPoint(x: 0, y: -berry.radius * 1.12), by: berry.angle, around: berry.center)
            return [[
                rotate(CGPoint(x: -berry.radius * 0.42, y: -berry.radius * 0.82), by: berry.angle, around: berry.center),
                cap,
                rotate(CGPoint(x: berry.radius * 0.42, y: -berry.radius * 0.82), by: berry.angle, around: berry.center)
            ]]
        default:
            return []
        }
    }

    static func importedVectorOutlines(_ vector: ImportedVectorElement) -> [[CGPoint]] {
        vector.outlines.map { outline in
            outline.map { point in
                rotate(
                    CGPoint(x: point.x * vector.size.width, y: point.y * vector.size.height),
                    by: vector.angle,
                    around: vector.center
                )
            }
        }
    }

    static func importedVectorColoredShapes(_ vector: ImportedVectorElement) -> [VectorShape] {
        vector.coloredShapes.map { shape in
            VectorShape(
                outline: shape.outline.map { point in
                    rotate(
                        CGPoint(x: point.x * vector.size.width, y: point.y * vector.size.height),
                        by: vector.angle,
                        around: vector.center
                    )
                },
                fillHex: shape.fillHex
            )
        }
    }

    static func birdBodyOutlines(_ bird: BirdElement) -> [[CGPoint]] {
        []
    }

    static func birdWingOutlines(_ bird: BirdElement) -> [[CGPoint]] {
        []
    }

    static func birdAccentLines(_ bird: BirdElement) -> [[CGPoint]] {
        switch bird.kind {
        case .hummingbird:
            return [
                birdIconLine(bird, [CGPoint(x: -0.95, y: 0.05), CGPoint(x: -0.36, y: -0.12), CGPoint(x: 0.28, y: -0.18), CGPoint(x: 0.54, y: -0.1), CGPoint(x: 1.28, y: -0.18), CGPoint(x: 0.56, y: 0.02), CGPoint(x: 0.18, y: 0.22), CGPoint(x: -0.4, y: 0.18), CGPoint(x: -0.95, y: 0.05)]),
                birdIconLine(bird, [CGPoint(x: -0.18, y: -0.04), CGPoint(x: -0.02, y: -0.62), CGPoint(x: 0.18, y: -0.08)]),
                birdIconLine(bird, [CGPoint(x: -0.18, y: 0.0), CGPoint(x: -0.04, y: 0.48), CGPoint(x: 0.16, y: 0.08)])
            ]
        case .kingfisher:
            return [
                birdIconLine(bird, [CGPoint(x: -0.9, y: 0.08), CGPoint(x: -0.32, y: -0.2), CGPoint(x: 0.34, y: -0.2), CGPoint(x: 0.64, y: -0.1), CGPoint(x: 1.16, y: -0.14), CGPoint(x: 0.62, y: 0.04), CGPoint(x: 0.22, y: 0.26), CGPoint(x: -0.42, y: 0.2), CGPoint(x: -0.9, y: 0.08)]),
                birdIconLine(bird, [CGPoint(x: -0.18, y: -0.02), CGPoint(x: 0.16, y: 0.06), CGPoint(x: -0.26, y: 0.18)])
            ]
        case .crane:
            return [
                birdIconLine(bird, [CGPoint(x: -0.92, y: 0.12), CGPoint(x: -0.38, y: -0.08), CGPoint(x: 0.22, y: -0.06), CGPoint(x: 0.5, y: -0.32), CGPoint(x: 0.72, y: -0.66), CGPoint(x: 1.0, y: -0.72), CGPoint(x: 0.7, y: -0.54), CGPoint(x: 0.52, y: -0.18), CGPoint(x: 0.24, y: 0.2), CGPoint(x: -0.42, y: 0.22), CGPoint(x: -0.92, y: 0.12)]),
                birdIconLine(bird, [CGPoint(x: -0.16, y: 0.0), CGPoint(x: 0.18, y: 0.1), CGPoint(x: -0.24, y: 0.18)]),
                birdIconLine(bird, [CGPoint(x: -0.1, y: 0.22), CGPoint(x: -0.2, y: 0.66)])
            ]
        case .owl:
            return [
                birdIconLine(bird, [CGPoint(x: -0.48, y: -0.42), CGPoint(x: -0.18, y: -0.62), CGPoint(x: 0.16, y: -0.62), CGPoint(x: 0.48, y: -0.42), CGPoint(x: 0.44, y: 0.26), CGPoint(x: 0.18, y: 0.58), CGPoint(x: -0.18, y: 0.58), CGPoint(x: -0.44, y: 0.26), CGPoint(x: -0.48, y: -0.42)]),
                birdIconLine(bird, [CGPoint(x: -0.24, y: -0.28), CGPoint(x: -0.1, y: -0.28)]),
                birdIconLine(bird, [CGPoint(x: 0.1, y: -0.28), CGPoint(x: 0.24, y: -0.28)]),
                birdIconLine(bird, [CGPoint(x: -0.08, y: -0.12), CGPoint(x: 0, y: 0.02), CGPoint(x: 0.08, y: -0.12)])
            ]
        case .swallow:
            return [
                birdIconLine(bird, [CGPoint(x: -0.98, y: 0.08), CGPoint(x: -0.42, y: -0.2), CGPoint(x: 0.32, y: -0.18), CGPoint(x: 0.62, y: -0.06), CGPoint(x: 0.96, y: -0.06), CGPoint(x: 0.62, y: 0.06), CGPoint(x: 0.2, y: 0.22), CGPoint(x: -0.4, y: 0.2), CGPoint(x: -0.98, y: 0.08)]),
                birdIconLine(bird, [CGPoint(x: -0.62, y: 0.08), CGPoint(x: -1.18, y: -0.28)]),
                birdIconLine(bird, [CGPoint(x: -0.62, y: 0.08), CGPoint(x: -1.18, y: 0.36)]),
                birdIconLine(bird, [CGPoint(x: -0.18, y: -0.02), CGPoint(x: 0.18, y: 0.08), CGPoint(x: -0.28, y: 0.18)])
            ]
        default:
            return [
                birdIconLine(bird, [CGPoint(x: -0.9, y: 0.1), CGPoint(x: -0.38, y: -0.18), CGPoint(x: 0.26, y: -0.18), CGPoint(x: 0.56, y: -0.08), CGPoint(x: 0.92, y: -0.06), CGPoint(x: 0.56, y: 0.04), CGPoint(x: 0.24, y: 0.26), CGPoint(x: -0.38, y: 0.22), CGPoint(x: -0.9, y: 0.1)]),
                birdIconLine(bird, [CGPoint(x: -0.2, y: -0.02), CGPoint(x: 0.14, y: 0.08), CGPoint(x: -0.28, y: 0.2)]),
                birdIconLine(bird, [CGPoint(x: -0.18, y: 0.22), CGPoint(x: -0.26, y: 0.54)]),
                birdIconLine(bird, [CGPoint(x: 0.04, y: 0.22), CGPoint(x: 0.08, y: 0.54)])
            ]
        }
    }

    static func curlPoints(_ curl: CurlElement) -> [CGPoint] {
        let steps = 42
        return (0...steps).map { index in
            let t = CGFloat(index) / CGFloat(steps)
            let angle = t * CGFloat.pi * 2.0 * curl.turns * curl.direction
            let radius = curl.radius * (1.0 - t * 0.72)
            return CGPoint(x: curl.center.x + cos(angle) * radius, y: curl.center.y + sin(angle) * radius)
        }
    }

    static func rotate(_ point: CGPoint, by angle: CGFloat, around center: CGPoint) -> CGPoint {
        CGPoint(
            x: center.x + point.x * cos(angle) - point.y * sin(angle),
            y: center.y + point.x * sin(angle) + point.y * cos(angle)
        )
    }

    private static func radialOvals(_ flower: FlowerElement, width: CGFloat, height: CGFloat, reach: CGFloat, steps: Int) -> [[CGPoint]] {
        (0..<flower.petals).map { petal in
            let angle = flower.angle + (CGFloat(petal) / CGFloat(flower.petals)) * CGFloat.pi * 2
            let center = CGPoint(
                x: flower.center.x + cos(angle) * flower.radius * reach,
                y: flower.center.y + sin(angle) * flower.radius * reach
            )
            return rotatedOval(
                center: center,
                width: flower.radius * width,
                height: flower.radius * height,
                angle: angle,
                steps: steps
            )
        }
    }

    private static func pointedPetal(center: CGPoint, radius: CGFloat, angle: CGFloat) -> [CGPoint] {
        [
            CGPoint(x: radius * 0.18, y: 0),
            CGPoint(x: radius * 0.86, y: -radius * 0.18),
            CGPoint(x: radius * 1.18, y: 0),
            CGPoint(x: radius * 0.86, y: radius * 0.18),
            CGPoint(x: radius * 0.18, y: 0)
        ].map { rotate($0, by: angle, around: center) }
    }

    private static func teardrop(center: CGPoint, width: CGFloat, height: CGFloat, angle: CGFloat, steps: Int) -> [CGPoint] {
        (0..<steps).map { index in
            let t = (CGFloat(index) / CGFloat(steps)) * CGFloat.pi * 2.0
            let taper = 0.44 + 0.56 * max(CGFloat(0), sin(t))
            let point = CGPoint(
                x: cos(t) * width * 0.5 * taper,
                y: sin(t) * height * 0.5
            )
            return rotate(point, by: angle, around: center)
        }
    }

    private static func bodyWidth(for kind: BirdKind) -> CGFloat {
        switch kind {
        case .dove, .gull:
            return 1.18
        case .crane:
            return 1.08
        case .hummingbird:
            return 0.82
        case .owl:
            return 0.82
        case .kingfisher:
            return 1.0
        default:
            return 0.98
        }
    }

    private static func bodyHeight(for kind: BirdKind) -> CGFloat {
        switch kind {
        case .owl:
            return 0.96
        case .crane, .hummingbird:
            return 0.5
        case .dove:
            return 0.72
        default:
            return 0.64
        }
    }

    private static func headX(for kind: BirdKind) -> CGFloat {
        switch kind {
        case .crane:
            return 0.62
        case .hummingbird:
            return 0.44
        case .owl:
            return 0.0
        default:
            return 0.48
        }
    }

    private static func headY(for kind: BirdKind) -> CGFloat {
        switch kind {
        case .owl:
            return -0.36
        case .crane:
            return -0.28
        case .hummingbird:
            return -0.1
        default:
            return -0.18
        }
    }

    private static func headSize(for kind: BirdKind) -> CGFloat {
        switch kind {
        case .owl:
            return 0.58
        case .dove, .kingfisher:
            return 0.42
        case .hummingbird, .crane:
            return 0.32
        default:
            return 0.36
        }
    }

    private static func tailShape(for bird: BirdElement) -> [CGPoint] {
        switch bird.kind {
        case .swallow:
            return birdShape(bird, [
                CGPoint(x: -0.52, y: 0.04),
                CGPoint(x: -1.05, y: -0.32),
                CGPoint(x: -0.82, y: 0.02),
                CGPoint(x: -1.08, y: 0.34)
            ])
        case .dove, .gull:
            return birdShape(bird, [
                CGPoint(x: -0.56, y: -0.08),
                CGPoint(x: -1.02, y: -0.18),
                CGPoint(x: -0.94, y: 0.18),
                CGPoint(x: -0.52, y: 0.14)
            ])
        case .hummingbird:
            return birdShape(bird, [
                CGPoint(x: -0.46, y: 0.0),
                CGPoint(x: -0.92, y: -0.22),
                CGPoint(x: -0.82, y: 0.18)
            ])
        case .owl:
            return birdShape(bird, [
                CGPoint(x: -0.28, y: 0.38),
                CGPoint(x: 0, y: 0.68),
                CGPoint(x: 0.28, y: 0.38)
            ])
        default:
            return birdShape(bird, [
                CGPoint(x: -0.48, y: -0.04),
                CGPoint(x: -0.96, y: -0.22),
                CGPoint(x: -0.82, y: 0.18)
            ])
        }
    }

    private static func beakShape(for bird: BirdElement) -> [CGPoint] {
        switch bird.kind {
        case .hummingbird:
            return birdShape(bird, [
                CGPoint(x: 0.58, y: -0.1),
                CGPoint(x: 1.28, y: -0.18),
                CGPoint(x: 0.58, y: 0.0)
            ])
        case .crane:
            return birdShape(bird, [
                CGPoint(x: 0.72, y: -0.3),
                CGPoint(x: 1.06, y: -0.38),
                CGPoint(x: 0.72, y: -0.22)
            ])
        case .kingfisher:
            return birdShape(bird, [
                CGPoint(x: 0.66, y: -0.16),
                CGPoint(x: 1.18, y: -0.22),
                CGPoint(x: 0.66, y: -0.06)
            ])
        case .owl:
            return birdShape(bird, [
                CGPoint(x: 0.0, y: -0.34),
                CGPoint(x: 0.1, y: -0.2),
                CGPoint(x: -0.1, y: -0.2)
            ])
        default:
            return birdShape(bird, [
                CGPoint(x: 0.62, y: -0.18),
                CGPoint(x: 0.96, y: -0.16),
                CGPoint(x: 0.62, y: -0.04)
            ])
        }
    }

    private static func birdPoint(_ bird: BirdElement, x: CGFloat, y: CGFloat) -> CGPoint {
        rotate(CGPoint(x: x * bird.size, y: y * bird.size), by: bird.angle, around: bird.center)
    }

    private static func birdShape(_ bird: BirdElement, _ points: [CGPoint]) -> [CGPoint] {
        points.map { birdPoint(bird, x: $0.x, y: $0.y) }
    }

    private static func birdIconLine(_ bird: BirdElement, _ points: [CGPoint]) -> [CGPoint] {
        points.map { birdPoint(bird, x: $0.x, y: $0.y) }
    }
}

private struct StitchBlockBuilder {
    let color: EmbroideryColor
    var points: [StitchPoint]
}
