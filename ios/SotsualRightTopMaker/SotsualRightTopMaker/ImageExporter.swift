import SwiftUI
import UIKit

enum AlbumImageExporter {
    static let outputSize = CGSize(width: 2048, height: 1536)
    static let photoAreaHeightRatio: CGFloat = 0.80

    static func render(template: PhotoTemplate, state: EditorState, absentImage: UIImage?) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: outputSize, format: format).image { context in
            let rect = CGRect(origin: .zero, size: outputSize)
            let photoRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height * photoAreaHeightRatio)
            drawTemplate(template, in: photoRect)
            applyFilter(state.filter, template: template, in: photoRect)
            drawAbsentPhoto(absentImage, template: template, state: state, in: photoRect)
            drawCaptionBackground(in: rect)
            drawAlbumText(state.text, in: rect, template: template)
        }
    }

    static func drawTemplate(_ template: PhotoTemplate, in rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        defer { context?.restoreGState() }

        if let imageName = template.imageName, let image = UIImage(named: imageName) {
            image.draw(in: rect)
            return
        }

        let sky = template.mood == .postwar ? UIColor(white: 0.72, alpha: 1) : UIColor(red: 0.72, green: 0.86, blue: 0.94, alpha: 1)
        sky.setFill()
        UIRectFill(rect)

        switch template.mood {
        case .graduation:
            drawSchool(rect: rect, wall: UIColor(red: 0.84, green: 0.76, blue: 0.63, alpha: 1), roof: UIColor(red: 0.28, green: 0.34, blue: 0.42, alpha: 1))
            drawTrees(rect: rect, flower: UIColor(red: 1.0, green: 0.74, blue: 0.80, alpha: 1))
            drawPeopleRows(rect: rect, uniform: UIColor(red: 0.12, green: 0.17, blue: 0.25, alpha: 1))
        case .trip:
            drawMountains(rect: rect)
            drawBus(rect: rect)
            drawPeopleRows(rect: rect, uniform: UIColor(red: 0.22, green: 0.36, blue: 0.56, alpha: 1))
        case .postwar:
            drawSchool(rect: rect, wall: UIColor(red: 0.56, green: 0.48, blue: 0.36, alpha: 1), roof: UIColor(red: 0.24, green: 0.22, blue: 0.18, alpha: 1))
            drawPeopleRows(rect: rect, uniform: UIColor(white: 0.18, alpha: 1))
        case .sports:
            UIColor(red: 0.74, green: 0.46, blue: 0.32, alpha: 1).setFill()
            UIRectFill(CGRect(x: 0, y: rect.height * 0.50, width: rect.width, height: rect.height * 0.50))
            drawFlags(rect: rect)
            drawPeopleRows(rect: rect, uniform: UIColor(red: 0.92, green: 0.12, blue: 0.10, alpha: 1))
        case .festival:
            drawClassroom(rect: rect)
            drawPeopleRows(rect: rect, uniform: UIColor(red: 0.25, green: 0.18, blue: 0.35, alpha: 1))
        case .amusement:
            drawPark(rect: rect)
            drawPeopleRows(rect: rect, uniform: UIColor(red: 0.18, green: 0.30, blue: 0.48, alpha: 1))
        case .forest:
            drawForest(rect: rect)
            drawPeopleRows(rect: rect, uniform: UIColor(red: 0.20, green: 0.36, blue: 0.20, alpha: 1))
        case .excursion:
            drawParkField(rect: rect)
            drawPeopleRows(rect: rect, uniform: UIColor(red: 0.16, green: 0.32, blue: 0.54, alpha: 1))
        case .meiji:
            drawSchool(rect: rect, wall: UIColor(red: 0.56, green: 0.48, blue: 0.36, alpha: 1), roof: UIColor(red: 0.24, green: 0.22, blue: 0.18, alpha: 1))
            drawPeopleRows(rect: rect, uniform: UIColor(white: 0.16, alpha: 1))
        case .mountain:
            drawMountains(rect: rect)
            drawPeopleRows(rect: rect, uniform: UIColor(red: 0.10, green: 0.20, blue: 0.32, alpha: 1))
        case .uniba:
            drawPark(rect: rect)
            drawPeopleRows(rect: rect, uniform: UIColor(red: 0.18, green: 0.30, blue: 0.48, alpha: 1))
        case .storage:
            drawSchool(rect: rect, wall: UIColor(red: 0.72, green: 0.74, blue: 0.72, alpha: 1), roof: UIColor(red: 0.56, green: 0.58, blue: 0.58, alpha: 1))
            drawPeopleRows(rect: rect, uniform: UIColor(red: 0.12, green: 0.17, blue: 0.25, alpha: 1))
        case .isekai:
            drawPark(rect: rect)
            drawPeopleRows(rect: rect, uniform: UIColor(red: 0.16, green: 0.20, blue: 0.34, alpha: 1))
        }

        UIColor(white: 0.97, alpha: 1).setFill()
        UIRectFill(CGRect(x: 0, y: rect.height * 0.82, width: rect.width, height: rect.height * 0.18))
        UIColor(white: 0.0, alpha: 0.08).setStroke()
        UIBezierPath(rect: CGRect(x: 0, y: rect.height * 0.82, width: rect.width, height: 2)).stroke()
    }

    private static func drawAspectFill(_ image: UIImage, in rect: CGRect) {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
        let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawRect = CGRect(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        image.draw(in: drawRect)
    }

    private static func drawAbsentPhoto(_ image: UIImage?, template: PhotoTemplate, state: EditorState, in rect: CGRect) {
        guard let image else { return }

        let side = rect.width * state.circleSize
        let frame = CGRect(
            x: rect.width * state.circleCenter.x - side / 2,
            y: rect.height * state.circleCenter.y - side / 2,
            width: side,
            height: side
        )

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        if state.showsShadow {
            context?.setShadow(offset: CGSize(width: 0, height: 12), blur: 18, color: UIColor.black.withAlphaComponent(0.32).cgColor)
        }

        let circle = UIBezierPath(ovalIn: frame)
        UIColor.white.setFill()
        circle.fill()
        context?.restoreGState()

        let inner = frame.insetBy(dx: state.showsBorder ? state.borderWidth : 0, dy: state.showsBorder ? state.borderWidth : 0)
        context?.saveGState()
        UIBezierPath(ovalIn: inner).addClip()

        let imageSide = max(inner.width, inner.height) * state.photoScale
        let drawRect = CGRect(
            x: inner.midX - imageSide / 2 + state.photoOffset.width * rect.width,
            y: inner.midY - imageSide / 2 + state.photoOffset.height * rect.height,
            width: imageSide,
            height: imageSide
        )
        context?.saveGState()
        context?.translateBy(x: inner.midX, y: inner.midY)
        context?.rotate(by: CGFloat(state.photoRotation.radians))
        context?.translateBy(x: -inner.midX, y: -inner.midY)
        image.draw(in: drawRect)
        context?.restoreGState()
        applyPhotoFilter(state.filter, template: template, in: inner)
        context?.restoreGState()

        if state.showsBorder {
            UIColor.white.setStroke()
            let border = UIBezierPath(ovalIn: frame.insetBy(dx: state.borderWidth / 2, dy: state.borderWidth / 2))
            border.lineWidth = state.borderWidth
            border.stroke()
        }
    }

    private static func applyPhotoFilter(_ filter: TemplateFilter, template: PhotoTemplate, in rect: CGRect) {
        switch filter {
        case .normal:
            return
        case .sepia:
            UIColor(red: 0.60, green: 0.43, blue: 0.24, alpha: 0.28).setFill()
            UIRectFillUsingBlendMode(rect, .sourceAtop)
        case .monochrome:
            UIColor.black.setFill()
            UIRectFillUsingBlendMode(rect, .saturation)
            if template.mood == .meiji {
                UIColor(white: 0.12, alpha: 0.18).setFill()
                UIRectFillUsingBlendMode(rect, .multiply)
                UIColor(white: 0.90, alpha: 0.05).setFill()
                UIRectFillUsingBlendMode(rect, .sourceAtop)
            } else {
                UIColor(red: 0.40, green: 0.34, blue: 0.24, alpha: 0.24).setFill()
                UIRectFillUsingBlendMode(rect, .sourceAtop)
                UIColor(white: 0.0, alpha: 0.12).setFill()
                UIRectFillUsingBlendMode(rect, .multiply)
            }
        }
    }

    private static func drawCaptionBackground(in rect: CGRect) {
        let bandY = rect.height * photoAreaHeightRatio
        UIColor(white: 0.98, alpha: 1).setFill()
        UIRectFill(CGRect(x: 0, y: bandY, width: rect.width, height: rect.height - bandY))
        UIColor(white: 0.0, alpha: 0.10).setStroke()
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: 0, y: bandY))
        divider.addLine(to: CGPoint(x: rect.width, y: bandY))
        divider.lineWidth = 2
        divider.stroke()
    }

    private static func drawAlbumText(_ text: AlbumText, in rect: CGRect, template: PhotoTemplate) {
        let titleRect = CGRect(x: rect.width * 0.08, y: rect.height * 0.825, width: rect.width * 0.84, height: 86)
        let schoolRect = CGRect(x: rect.width * 0.08, y: rect.height * 0.895, width: rect.width * 0.84, height: 64)
        let noteRect = CGRect(x: rect.width * 0.08, y: rect.height * 0.942, width: rect.width * 0.84, height: 44)

        drawCenteredText(text.titleLine, in: titleRect, size: 64, weight: .bold, color: .black, tracking: 10)
        drawCenteredText(text.schoolLine, in: schoolRect, size: 50, weight: .semibold, color: UIColor(white: 0.08, alpha: 1), tracking: 8)

        let note = [text.absenteeName.isEmpty ? nil : "欠席者: \(text.absenteeName)", text.comment.isEmpty ? nil : text.comment].compactMap { $0 }.joined(separator: "　")
        if !note.isEmpty {
            drawCenteredText(note, in: noteRect, size: 30, weight: .regular, color: UIColor(white: 0.24, alpha: 1), tracking: 2)
        }
    }

    private static func drawCenteredText(_ value: String, in rect: CGRect, size: CGFloat, weight: UIFont.Weight, color: UIColor, tracking: CGFloat = 0) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let font = UIFont(name: "Hiragino Mincho ProN W6", size: size) ?? UIFont.systemFont(ofSize: size, weight: weight)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .kern: tracking,
            .paragraphStyle: paragraph
        ]
        NSString(string: value).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
    }

    private static func applyFilter(_ filter: TemplateFilter, template: PhotoTemplate, in rect: CGRect) {
        switch filter {
        case .normal:
            return
        case .sepia:
            UIColor(red: 0.56, green: 0.36, blue: 0.16, alpha: 0.22).setFill()
            UIRectFillUsingBlendMode(rect, .sourceAtop)
        case .monochrome:
            UIColor.black.setFill()
            UIRectFillUsingBlendMode(rect, .saturation)
            if template.mood == .meiji {
                UIColor(white: 0.12, alpha: 0.16).setFill()
                UIRectFillUsingBlendMode(rect, .multiply)
                UIColor(white: 0.92, alpha: 0.05).setFill()
                UIRectFillUsingBlendMode(rect, .sourceAtop)
            } else {
                UIColor(red: 0.40, green: 0.34, blue: 0.24, alpha: 0.20).setFill()
                UIRectFillUsingBlendMode(rect, .sourceAtop)
                UIColor(white: 0.0, alpha: 0.10).setFill()
                UIRectFillUsingBlendMode(rect, .multiply)
            }
        }
    }

    private static func drawSchool(rect: CGRect, wall: UIColor, roof: UIColor) {
        wall.setFill()
        UIRectFill(CGRect(x: rect.width * 0.18, y: rect.height * 0.22, width: rect.width * 0.64, height: rect.height * 0.30))
        roof.setFill()
        UIBezierPath(rect: CGRect(x: rect.width * 0.15, y: rect.height * 0.18, width: rect.width * 0.70, height: rect.height * 0.06)).fill()
        UIColor.white.withAlphaComponent(0.65).setFill()
        for row in 0..<3 {
            for column in 0..<8 {
                UIRectFill(CGRect(x: rect.width * (0.22 + CGFloat(column) * 0.07), y: rect.height * (0.27 + CGFloat(row) * 0.07), width: rect.width * 0.038, height: rect.height * 0.035))
            }
        }
        UIColor(red: 0.38, green: 0.55, blue: 0.36, alpha: 1).setFill()
        UIRectFill(CGRect(x: 0, y: rect.height * 0.52, width: rect.width, height: rect.height * 0.30))
    }

    private static func drawPeopleRows(rect: CGRect, uniform: UIColor) {
        for row in 0..<3 {
            let count = row == 0 ? 12 : 14
            let y = rect.height * (0.56 + CGFloat(row) * 0.075)
            let start = rect.width * 0.18
            let gap = rect.width * 0.64 / CGFloat(count - 1)
            for index in 0..<count {
                let x = start + CGFloat(index) * gap
                UIColor(red: 0.78, green: 0.57, blue: 0.42, alpha: 1).setFill()
                UIBezierPath(ovalIn: CGRect(x: x - 14, y: y - 42, width: 28, height: 32)).fill()
                uniform.setFill()
                UIBezierPath(roundedRect: CGRect(x: x - 22, y: y - 12, width: 44, height: 54), cornerRadius: 8).fill()
            }
        }
    }

    private static func drawTrees(rect: CGRect, flower: UIColor) {
        for x in [0.08, 0.90] {
            UIColor(red: 0.42, green: 0.25, blue: 0.12, alpha: 1).setFill()
            UIRectFill(CGRect(x: rect.width * x, y: rect.height * 0.32, width: 24, height: 260))
            flower.setFill()
            UIBezierPath(ovalIn: CGRect(x: rect.width * x - 80, y: rect.height * 0.18, width: 190, height: 170)).fill()
        }
    }

    private static func drawMountains(rect: CGRect) {
        UIColor(red: 0.43, green: 0.56, blue: 0.48, alpha: 1).setFill()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.48))
        path.addLine(to: CGPoint(x: rect.width * 0.22, y: rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.width * 0.48, y: rect.height * 0.48))
        path.addLine(to: CGPoint(x: rect.width * 0.70, y: rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.48))
        path.close()
        path.fill()
        UIColor(red: 0.40, green: 0.62, blue: 0.36, alpha: 1).setFill()
        UIRectFill(CGRect(x: 0, y: rect.height * 0.48, width: rect.width, height: rect.height * 0.34))
    }

    private static func drawBus(rect: CGRect) {
        UIColor(red: 0.96, green: 0.78, blue: 0.20, alpha: 1).setFill()
        UIBezierPath(roundedRect: CGRect(x: rect.width * 0.55, y: rect.height * 0.38, width: rect.width * 0.32, height: rect.height * 0.14), cornerRadius: 18).fill()
        UIColor.white.withAlphaComponent(0.8).setFill()
        for index in 0..<4 {
            UIRectFill(CGRect(x: rect.width * (0.58 + CGFloat(index) * 0.065), y: rect.height * 0.405, width: rect.width * 0.045, height: rect.height * 0.04))
        }
    }

    private static func drawFlags(rect: CGRect) {
        for index in 0..<9 {
            let x = rect.width * 0.10 + CGFloat(index) * rect.width * 0.10
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: rect.height * 0.24))
            path.addLine(to: CGPoint(x: x + 56, y: rect.height * 0.28))
            path.addLine(to: CGPoint(x: x, y: rect.height * 0.32))
            path.close()
            (index % 2 == 0 ? UIColor.red : UIColor.white).setFill()
            path.fill()
        }
    }

    private static func drawClassroom(rect: CGRect) {
        UIColor(red: 0.84, green: 0.78, blue: 0.66, alpha: 1).setFill()
        UIRectFill(rect)
        UIColor(red: 0.18, green: 0.38, blue: 0.28, alpha: 1).setFill()
        UIRectFill(CGRect(x: rect.width * 0.18, y: rect.height * 0.18, width: rect.width * 0.64, height: rect.height * 0.22))
        UIColor(red: 0.93, green: 0.35, blue: 0.42, alpha: 1).setFill()
        for index in 0..<10 {
            UIBezierPath(ovalIn: CGRect(x: rect.width * 0.08 + CGFloat(index) * rect.width * 0.09, y: rect.height * 0.08, width: 34, height: 34)).fill()
        }
    }

    private static func drawPark(rect: CGRect) {
        UIColor(red: 0.64, green: 0.86, blue: 0.96, alpha: 1).setFill()
        UIRectFill(rect)
        UIColor(red: 0.34, green: 0.62, blue: 0.32, alpha: 1).setFill()
        UIRectFill(CGRect(x: 0, y: rect.height * 0.56, width: rect.width, height: rect.height * 0.26))
        UIColor(red: 0.92, green: 0.30, blue: 0.36, alpha: 1).setStroke()
        let wheel = UIBezierPath(ovalIn: CGRect(x: rect.width * 0.62, y: rect.height * 0.17, width: 260, height: 260))
        wheel.lineWidth = 12
        wheel.stroke()
        UIColor(red: 0.24, green: 0.35, blue: 0.55, alpha: 1).setStroke()
        let coaster = UIBezierPath()
        coaster.move(to: CGPoint(x: rect.width * 0.06, y: rect.height * 0.42))
        coaster.addCurve(to: CGPoint(x: rect.width * 0.55, y: rect.height * 0.36), controlPoint1: CGPoint(x: rect.width * 0.22, y: rect.height * 0.20), controlPoint2: CGPoint(x: rect.width * 0.36, y: rect.height * 0.56))
        coaster.lineWidth = 12
        coaster.stroke()
    }

    private static func drawForest(rect: CGRect) {
        UIColor(red: 0.62, green: 0.78, blue: 0.72, alpha: 1).setFill()
        UIRectFill(rect)
        UIColor(red: 0.16, green: 0.38, blue: 0.20, alpha: 1).setFill()
        for index in 0..<16 {
            let x = CGFloat(index) * rect.width / 15
            let tree = UIBezierPath()
            tree.move(to: CGPoint(x: x, y: rect.height * 0.16))
            tree.addLine(to: CGPoint(x: x - 70, y: rect.height * 0.55))
            tree.addLine(to: CGPoint(x: x + 70, y: rect.height * 0.55))
            tree.close()
            tree.fill()
        }
        UIColor(red: 0.68, green: 0.48, blue: 0.25, alpha: 1).setFill()
        UIRectFill(CGRect(x: rect.width * 0.56, y: rect.height * 0.42, width: rect.width * 0.22, height: rect.height * 0.14))
    }

    private static func drawParkField(rect: CGRect) {
        UIColor(red: 0.68, green: 0.86, blue: 0.96, alpha: 1).setFill()
        UIRectFill(rect)
        UIColor(red: 0.38, green: 0.66, blue: 0.34, alpha: 1).setFill()
        UIRectFill(CGRect(x: 0, y: rect.height * 0.46, width: rect.width, height: rect.height * 0.36))
        UIColor(red: 0.86, green: 0.42, blue: 0.16, alpha: 1).setFill()
        UIBezierPath(roundedRect: CGRect(x: rect.width * 0.68, y: rect.height * 0.42, width: rect.width * 0.18, height: rect.height * 0.08), cornerRadius: 18).fill()
    }
}

final class PhotoSaveHandler: NSObject {
    var completion: ((Bool, Error?) -> Void)?

    func save(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        completion?(error == nil, error)
    }
}
