import Photos
import SwiftUI

struct AnnotatorView: View {
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let items: [MeasurementItem]

    @State private var annotations: [Annotation] = []
    @State private var selectedItem: MeasurementItem?
    @State private var pendingStart: CGPoint?
    @State private var exportedImage: UIImage?
    @State private var showShare = false
    @State private var saveMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    let frame = imageFrame(in: geometry.size)

                    ZStack {
                        Color(.systemGroupedBackground)

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()

                        ForEach(annotations) { annotation in
                            let start = denorm(annotation.start, frame)
                            let end = denorm(annotation.end, frame)

                            ArrowShape(start: start, end: end)
                                .stroke(.red, lineWidth: 3)

                            Text(annotation.valueText)
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.88), in: RoundedRectangle(cornerRadius: 5))
                                .foregroundStyle(.red)
                                .position(midpoint(start, end, offsetY: -18))
                        }

                        if let pendingStart {
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                                .position(denorm(pendingStart, frame))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        handleTap(location, frame: frame)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(instruction)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(items) { item in
                                let placed = annotations.contains { $0.itemName == item.name }
                                Button {
                                    selectedItem = item
                                    pendingStart = nil
                                } label: {
                                    Label(item.label, systemImage: placed ? "checkmark.circle.fill" : "circle")
                                }
                                .buttonStyle(.bordered)
                                .tint(selectedItem?.id == item.id ? .red : (placed ? .green : .gray))
                            }
                        }
                        .padding(.horizontal)
                    }

                    if let saveMessage {
                        Text(saveMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 10)
                .background(.bar)
            }
            .navigationTitle("寸法を書き込む")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(isSaving ? "保存中" : "保存") {
                        save()
                    }
                    .disabled(annotations.isEmpty || isSaving)
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("最後の線を削除", systemImage: "arrow.uturn.backward") {
                        if !annotations.isEmpty {
                            annotations.removeLast()
                        }
                    }
                    .disabled(annotations.isEmpty)
                }
            }
            .sheet(isPresented: $showShare) {
                if let exportedImage {
                    ShareSheet(items: [exportedImage])
                }
            }
        }
    }

    private var instruction: String {
        if selectedItem == nil {
            return "下の項目を選んでください。"
        }
        if pendingStart == nil {
            return "写真上で測り始めの位置をタップしてください。"
        }
        return "測り終わりの位置をタップしてください。"
    }

    private func handleTap(_ location: CGPoint, frame: CGRect) {
        guard let item = selectedItem, frame.contains(location) else { return }

        let point = norm(location, frame)
        if let start = pendingStart {
            annotations.removeAll { $0.itemName == item.name }
            annotations.append(Annotation(itemName: item.name,
                                          valueText: item.label,
                                          start: start,
                                          end: point))
            pendingStart = nil
            selectedItem = nil
        } else {
            pendingStart = point
        }
    }

    private func save() {
        let renderedImage = renderImage()
        exportedImage = renderedImage
        isSaving = true
        saveMessage = nil

        Task {
            do {
                try await saveToPhotoLibrary(renderedImage)
                await MainActor.run {
                    saveMessage = "写真に保存しました。"
                    isSaving = false
                    showShare = true
                }
            } catch {
                await MainActor.run {
                    saveMessage = "保存できませんでした。共有から保存してください。"
                    isSaving = false
                    showShare = true
                }
            }
        }
    }

    private func renderImage() -> UIImage {
        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            image.draw(at: .zero)

            let cgContext = context.cgContext
            let lineWidth = max(size.width, size.height) * 0.004
            let fontSize = max(size.width, size.height) * 0.025

            for annotation in annotations {
                let start = CGPoint(x: annotation.start.x * size.width, y: annotation.start.y * size.height)
                let end = CGPoint(x: annotation.end.x * size.width, y: annotation.end.y * size.height)

                cgContext.setStrokeColor(UIColor.systemRed.cgColor)
                cgContext.setLineWidth(lineWidth)
                drawArrow(cgContext, from: start, to: end, headLength: lineWidth * 5)

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: fontSize),
                    .foregroundColor: UIColor.systemRed
                ]
                let text = NSAttributedString(string: annotation.valueText, attributes: attributes)
                let textSize = text.size()
                let textOrigin = CGPoint(x: (start.x + end.x) / 2 - textSize.width / 2,
                                         y: (start.y + end.y) / 2 - textSize.height - lineWidth * 3)
                let backgroundRect = CGRect(origin: textOrigin, size: textSize)
                    .insetBy(dx: -fontSize * 0.25, dy: -fontSize * 0.15)

                cgContext.setFillColor(UIColor.white.withAlphaComponent(0.88).cgColor)
                cgContext.addPath(UIBezierPath(roundedRect: backgroundRect, cornerRadius: fontSize * 0.2).cgPath)
                cgContext.fillPath()
                text.draw(at: textOrigin)
            }
        }
    }

    private func saveToPhotoLibrary(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw SaveError.permissionDenied
        }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    private func drawArrow(_ context: CGContext, from start: CGPoint, to end: CGPoint, headLength: CGFloat) {
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        for (tip, base) in [(start, end), (end, start)] {
            let angle = atan2(tip.y - base.y, tip.x - base.x)
            for delta in [CGFloat.pi * 0.85, -CGFloat.pi * 0.85] {
                let point = CGPoint(x: tip.x + headLength * cos(angle + delta),
                                    y: tip.y + headLength * sin(angle + delta))
                context.move(to: tip)
                context.addLine(to: point)
            }
        }
        context.strokePath()
    }

    private func imageFrame(in container: CGSize) -> CGRect {
        let scale = min(container.width / image.size.width,
                        container.height / image.size.height)
        let width = image.size.width * scale
        let height = image.size.height * scale
        return CGRect(x: (container.width - width) / 2,
                      y: (container.height - height) / 2,
                      width: width,
                      height: height)
    }

    private func norm(_ point: CGPoint, _ frame: CGRect) -> CGPoint {
        CGPoint(x: (point.x - frame.minX) / frame.width,
                y: (point.y - frame.minY) / frame.height)
    }

    private func denorm(_ point: CGPoint, _ frame: CGRect) -> CGPoint {
        CGPoint(x: frame.minX + point.x * frame.width,
                y: frame.minY + point.y * frame.height)
    }

    private func midpoint(_ start: CGPoint, _ end: CGPoint, offsetY: CGFloat) -> CGPoint {
        CGPoint(x: (start.x + end.x) / 2,
                y: (start.y + end.y) / 2 + offsetY)
    }
}

struct ArrowShape: Shape {
    let start: CGPoint
    let end: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)

        let head: CGFloat = 12
        for (tip, base) in [(start, end), (end, start)] {
            let angle = atan2(tip.y - base.y, tip.x - base.x)
            for delta in [CGFloat.pi * 0.85, -CGFloat.pi * 0.85] {
                path.move(to: tip)
                path.addLine(to: CGPoint(x: tip.x + head * cos(angle + delta),
                                         y: tip.y + head * sin(angle + delta)))
            }
        }
        return path
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ viewController: UIActivityViewController, context: Context) {}
}

private enum SaveError: Error {
    case permissionDenied
}
