import SwiftUI
import UIKit

struct ReelPreview<EmptyAction: View>: View {
    var scene: ReelScene?
    var sceneIndex: Int
    var isExporting: Bool
    var emptyAction: EmptyAction

    init(
        scene: ReelScene?,
        sceneIndex: Int,
        isExporting: Bool,
        @ViewBuilder emptyAction: () -> EmptyAction
    ) {
        self.scene = scene
        self.sceneIndex = sceneIndex
        self.isExporting = isExporting
        self.emptyAction = emptyAction()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(red: 0.08, green: 0.07, blue: 0.06))
                .shadow(color: .black.opacity(0.2), radius: 0, x: 10, y: 10)

            ZStack {
                if let scene {
                    GeometryReader { proxy in
                        let canvasSize = proxy.size

                        Image(uiImage: scene.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: canvasSize.width, height: canvasSize.height)
                            .clipped()
                            .scaleEffect(1.06)

                        LinearGradient(
                            colors: [.black.opacity(0.28), .clear, .black.opacity(0.58)],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        Text("SCENE \(sceneIndex + 1)")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.yellow.opacity(0.88), in: RoundedRectangle(cornerRadius: 6))
                            .rotationEffect(.degrees(-4))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(20)

                        ForEach(Array(scene.motionStickers.enumerated()), id: \.element.id) { index, item in
                            MotionStickerView(item: item, layerIndex: index, canvasSize: canvasSize)
                        }

                        ForEach(Array(scene.textStickers.enumerated()), id: \.element.id) { index, item in
                            TextStickerView(item: item, layerIndex: index, canvasSize: canvasSize)
                        }

                        CaptionPreview(text: scene.caption)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .padding(.horizontal, 22)
                            .padding(.bottom, 38)
                    }
                } else {
                    GeometryReader { proxy in
                        Image("ReelHeroBackdrop")
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()

                        LinearGradient(
                            colors: [.white.opacity(0.12), .black.opacity(0.2), .black.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        VStack(spacing: 14) {
                            emptyAction
                            Text("写真を追加すると、縦長の商品紹介リールを作れます。")
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.75), radius: 0, x: 2, y: 2)
                                .padding(.horizontal, 22)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }

                if isExporting {
                    Color.black.opacity(0.34)
                    ProgressView("保存中")
                        .padding(14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .padding(10)
        }
        .aspectRatio(9 / 16, contentMode: .fit)
    }
}

struct CaptionPreview: View {
    var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(captionLines(text), id: \.self) { line in
                Text(line)
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 0, x: 3, y: 3)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Rectangle()
                .fill(Color.red)
                .frame(width: 120, height: 8)
                .padding(.top, 4)
        }
        .rotationEffect(.degrees(-2))
    }

    private func captionLines(_ text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [""] }
        if trimmed.count <= 12 { return [trimmed] }
        let chars = Array(trimmed)
        let midpoint = min(12, max(6, Int(ceil(Double(chars.count) / 2.0))))
        let punctuation = ["、", "。", "!", "?", "！", "？"]
        let breakIndex = (5..<min(chars.count, 15)).min { left, right in
            let leftScore = (punctuation.contains(String(chars[left])) ? 0 : 8) + abs(left - midpoint)
            let rightScore = (punctuation.contains(String(chars[right])) ? 0 : 8) + abs(right - midpoint)
            return leftScore < rightScore
        } ?? midpoint
        let first = String(chars[0...breakIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        let second = String(chars[(breakIndex + 1)..<chars.count]).trimmingCharacters(in: .whitespacesAndNewlines)
        return second.isEmpty ? [first] : [first, second]
    }
}

struct TextStickerView: View {
    var item: PlacedTextSticker
    var layerIndex: Int
    var canvasSize: CGSize

    var body: some View {
        Image(item.sticker.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: item.sticker.text.contains("\n") ? 168 : 188)
            .shadow(color: .black.opacity(0.38), radius: 0, x: 5, y: 5)
            .rotationEffect(.degrees(item.sticker.tilt))
            .scaleEffect(item.scale * max(0.78, 1 - CGFloat(layerIndex) * 0.05))
            .position(layerPoint(for: item.position, layerIndex: layerIndex, in: canvasSize))
    }
}

struct MotionStickerView: View {
    var item: PlacedMotionSticker
    var layerIndex: Int
    var canvasSize: CGSize

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(0..<10, id: \.self) { index in
                    SparkleShape(kind: item.sticker.kind)
                        .fill(item.sticker.color.opacity(0.9))
                        .frame(width: 10 + CGFloat(index % 4) * 5, height: 10 + CGFloat(index % 4) * 5)
                        .offset(
                            x: cos(t * 2.4 + Double(index)) * CGFloat(28 + index * 5),
                            y: sin(t * 2.1 + Double(index) * 0.8) * CGFloat(20 + index * 4)
                        )
                }
            }
            .scaleEffect(item.scale * max(0.8, 1 - CGFloat(layerIndex) * 0.05))
            .position(layerPoint(for: item.position, layerIndex: layerIndex, in: canvasSize))
        }
    }
}

struct SparkleShape: Shape {
    var kind: MotionKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .hearts:
            var path = Path()
            let w = rect.width
            let h = rect.height
            path.move(to: CGPoint(x: w * 0.5, y: h * 0.9))
            path.addCurve(to: CGPoint(x: 0, y: h * 0.28), control1: CGPoint(x: w * 0.2, y: h * 0.65), control2: CGPoint(x: 0, y: h * 0.45))
            path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.25), control1: CGPoint(x: 0, y: 0), control2: CGPoint(x: w * 0.42, y: 0))
            path.addCurve(to: CGPoint(x: w, y: h * 0.28), control1: CGPoint(x: w * 0.58, y: 0), control2: CGPoint(x: w, y: 0))
            path.addCurve(to: CGPoint(x: w * 0.5, y: h * 0.9), control1: CGPoint(x: w, y: h * 0.45), control2: CGPoint(x: w * 0.8, y: h * 0.65))
            return path
        case .ring:
            return Path(ellipseIn: rect.insetBy(dx: rect.width * 0.18, dy: rect.height * 0.18))
        default:
            var path = Path()
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.midY - rect.height * 0.18))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.midY + rect.height * 0.18))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.midY + rect.height * 0.18))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.midY - rect.height * 0.18))
            path.closeSubpath()
            return path
        }
    }
}

private func layerPoint(for position: LayerPosition, layerIndex: Int, in size: CGSize) -> CGPoint {
    let base = position.unitPoint
    let offsets: [CGPoint] = [
        .zero, CGPoint(x: 18, y: -12), CGPoint(x: -18, y: 14), CGPoint(x: 24, y: 18), CGPoint(x: -24, y: -16)
    ]
    let offset = offsets[layerIndex % offsets.count]
    return CGPoint(x: base.x * size.width + offset.x, y: base.y * size.height + offset.y)
}
