import CoreGraphics
import Foundation
import UIKit

enum ImageVectorizer {
    static func template(from data: Data) -> VectorTemplate? {
        guard let image = UIImage(data: data) else { return nil }
        let target = CGSize(width: 160, height: 160)
        let renderer = UIGraphicsImageRenderer(size: target)
        let rendered = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: target))
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        guard let cgImage = rendered.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let didDraw = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard didDraw else { return nil }

        var luminanceValues: [Double] = []
        var transparentCount = 0
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let alpha = pixels[offset + 3]
                if alpha < 24 {
                    transparentCount += 1
                    continue
                }
                let red = Double(pixels[offset]) / 255.0
                let green = Double(pixels[offset + 1]) / 255.0
                let blue = Double(pixels[offset + 2]) / 255.0
                luminanceValues.append(red * 0.299 + green * 0.587 + blue * 0.114)
            }
        }
        guard !luminanceValues.isEmpty else { return nil }

        let average = luminanceValues.reduce(0, +) / Double(luminanceValues.count)
        let hasAlphaShape = Double(transparentCount) / Double(width * height) > 0.08
        let threshold = min(0.86, max(0.22, average * 0.92))

        var rawMask = [Bool](repeating: false, count: width * height)
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let alpha = Double(pixels[offset + 3]) / 255.0
                let red = Double(pixels[offset]) / 255.0
                let green = Double(pixels[offset + 1]) / 255.0
                let blue = Double(pixels[offset + 2]) / 255.0
                let luminance = red * 0.299 + green * 0.587 + blue * 0.114
                let filled = hasAlphaShape ? alpha > 0.12 : luminance < threshold
                if filled {
                    rawMask[y * width + x] = true
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard minX < maxX, minY < maxY else { return fallbackTemplate() }
        let rawBounds = (minX: minX, minY: minY, maxX: maxX, maxY: maxY)
        let mask = largestComponent(close(open(rawMask, width: width, height: height), width: width, height: height), width: width, height: height)
        guard let bounds = bounds(of: mask, width: width, height: height) else {
            return fallbackTemplate(bounds: rawBounds)
        }
        minX = bounds.minX
        minY = bounds.minY
        maxX = bounds.maxX
        maxY = bounds.maxY

        let boundary = boundaryPoints(mask, width: width, height: height)
        guard boundary.count >= 12 else {
            return fallbackTemplate(bounds: rawBounds)
        }

        let centerX = Double(minX + maxX) / 2.0
        let centerY = Double(minY + maxY) / 2.0
        let scale = Double(max(maxX - minX, maxY - minY))
        guard scale > 0 else { return fallbackTemplate(bounds: rawBounds) }

        let sorted = boundary.sorted { lhs, rhs in
            let leftAngle = atan2(Double(lhs.y) - centerY, Double(lhs.x) - centerX)
            let rightAngle = atan2(Double(rhs.y) - centerY, Double(rhs.x) - centerX)
            if abs(leftAngle - rightAngle) > 0.0001 {
                return leftAngle < rightAngle
            }
            let leftDistance = hypot(Double(lhs.x) - centerX, Double(lhs.y) - centerY)
            let rightDistance = hypot(Double(rhs.x) - centerX, Double(rhs.y) - centerY)
            return leftDistance > rightDistance
        }
        let reduced = simplify(sorted.map {
            CGPoint(x: (Double($0.x) - centerX) / scale, y: (Double($0.y) - centerY) / scale)
        }, tolerance: 0.018)

        let outline = resample(reduced, maxPoints: 180)
        guard outline.count >= 8 else { return fallbackTemplate(bounds: rawBounds) }
        let stipples = stippleOutlines(mask: rawMask, width: width, height: height, bounds: rawBounds, maxShapes: 120)
        return VectorTemplate(outlines: [outline] + stipples)
    }

    private static func fallbackTemplate(bounds: (minX: Int, minY: Int, maxX: Int, maxY: Int)? = nil) -> VectorTemplate {
        let widthRatio: CGFloat
        if let bounds {
            let w = CGFloat(max(1, bounds.maxX - bounds.minX))
            let h = CGFloat(max(1, bounds.maxY - bounds.minY))
            widthRatio = min(1.25, max(0.55, w / h))
        } else {
            widthRatio = 0.9
        }
        let outline = [
            CGPoint(x: 0, y: -0.5),
            CGPoint(x: 0.42 * widthRatio, y: -0.22),
            CGPoint(x: 0.5 * widthRatio, y: 0.18),
            CGPoint(x: 0.18 * widthRatio, y: 0.48),
            CGPoint(x: -0.24 * widthRatio, y: 0.42),
            CGPoint(x: -0.5 * widthRatio, y: 0.06),
            CGPoint(x: -0.34 * widthRatio, y: -0.34)
        ]
        return VectorTemplate(outlines: [outline])
    }

    private static func open(_ mask: [Bool], width: Int, height: Int) -> [Bool] {
        dilate(erode(mask, width: width, height: height), width: width, height: height)
    }

    private static func close(_ mask: [Bool], width: Int, height: Int) -> [Bool] {
        erode(dilate(mask, width: width, height: height), width: width, height: height)
    }

    private static func erode(_ mask: [Bool], width: Int, height: Int) -> [Bool] {
        var output = mask
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                var keep = true
                for dy in -1...1 {
                    for dx in -1...1 where !mask[(y + dy) * width + (x + dx)] {
                        keep = false
                    }
                }
                output[y * width + x] = keep
            }
        }
        return output
    }

    private static func dilate(_ mask: [Bool], width: Int, height: Int) -> [Bool] {
        var output = mask
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                var fill = false
                for dy in -1...1 {
                    for dx in -1...1 where mask[(y + dy) * width + (x + dx)] {
                        fill = true
                    }
                }
                output[y * width + x] = fill
            }
        }
        return output
    }

    private static func largestComponent(_ mask: [Bool], width: Int, height: Int) -> [Bool] {
        var visited = [Bool](repeating: false, count: mask.count)
        var best: [Int] = []

        for index in mask.indices where mask[index] && !visited[index] {
            var queue = [index]
            var component: [Int] = []
            visited[index] = true

            while let current = queue.popLast() {
                component.append(current)
                let x = current % width
                let y = current / width
                for neighbor in neighbors(x: x, y: y, width: width, height: height) {
                    if mask[neighbor] && !visited[neighbor] {
                        visited[neighbor] = true
                        queue.append(neighbor)
                    }
                }
            }

            if component.count > best.count {
                best = component
            }
        }

        var output = [Bool](repeating: false, count: mask.count)
        for index in best {
            output[index] = true
        }
        return output
    }

    private static func neighbors(x: Int, y: Int, width: Int, height: Int) -> [Int] {
        var items: [Int] = []
        for dy in -1...1 {
            for dx in -1...1 where dx != 0 || dy != 0 {
                let nx = x + dx
                let ny = y + dy
                if nx >= 0, nx < width, ny >= 0, ny < height {
                    items.append(ny * width + nx)
                }
            }
        }
        return items
    }

    private static func bounds(of mask: [Bool], width: Int, height: Int) -> (minX: Int, minY: Int, maxX: Int, maxY: Int)? {
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        var found = false
        for y in 0..<height {
            for x in 0..<width where mask[y * width + x] {
                found = true
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
        return found ? (minX, minY, maxX, maxY) : nil
    }

    private static func boundaryPoints(_ mask: [Bool], width: Int, height: Int) -> [CGPoint] {
        var points: [CGPoint] = []
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) where mask[y * width + x] {
                let hasEmptyNeighbor = neighbors(x: x, y: y, width: width, height: height).contains { !mask[$0] }
                if hasEmptyNeighbor {
                    points.append(CGPoint(x: x, y: y))
                }
            }
        }
        return points
    }

    private static func simplify(_ points: [CGPoint], tolerance: CGFloat) -> [CGPoint] {
        guard points.count > 3 else { return points }
        var output: [CGPoint] = []
        for point in points {
            guard let last = output.last else {
                output.append(point)
                continue
            }
            if hypot(point.x - last.x, point.y - last.y) >= tolerance {
                output.append(point)
            }
        }
        return output.count >= 3 ? output : points
    }

    private static func resample(_ points: [CGPoint], maxPoints: Int) -> [CGPoint] {
        guard points.count > maxPoints else { return points }
        let stride = Double(points.count) / Double(maxPoints)
        return (0..<maxPoints).map { points[min(points.count - 1, Int((Double($0) * stride).rounded(.down)))] }
    }

    private static func stippleOutlines(
        mask: [Bool],
        width: Int,
        height: Int,
        bounds: (minX: Int, minY: Int, maxX: Int, maxY: Int),
        maxShapes: Int
    ) -> [[CGPoint]] {
        let boxWidth = max(1, bounds.maxX - bounds.minX)
        let boxHeight = max(1, bounds.maxY - bounds.minY)
        let centerX = Double(bounds.minX + bounds.maxX) / 2.0
        let centerY = Double(bounds.minY + bounds.maxY) / 2.0
        let scale = Double(max(boxWidth, boxHeight))
        let cell = max(4, Int((Double(max(boxWidth, boxHeight)) / 22.0).rounded()))
        var outlines: [[CGPoint]] = []

        for y in stride(from: bounds.minY, through: bounds.maxY, by: cell) {
            for x in stride(from: bounds.minX, through: bounds.maxX, by: cell) {
                var filled = 0
                var total = 0
                for py in y..<min(height, y + cell) {
                    for px in x..<min(width, x + cell) {
                        total += 1
                        if mask[py * width + px] {
                            filled += 1
                        }
                    }
                }
                guard total > 0, Double(filled) / Double(total) > 0.28 else { continue }
                let cx = Double(x + cell / 2)
                let cy = Double(y + cell / 2)
                let dot = min(0.038, max(0.015, Double(cell) / scale * 0.42))
                outlines.append([
                    CGPoint(x: (cx - centerX) / scale, y: (cy - centerY) / scale - dot),
                    CGPoint(x: (cx - centerX) / scale + dot, y: (cy - centerY) / scale),
                    CGPoint(x: (cx - centerX) / scale, y: (cy - centerY) / scale + dot),
                    CGPoint(x: (cx - centerX) / scale - dot, y: (cy - centerY) / scale)
                ])
                if outlines.count >= maxShapes {
                    return outlines
                }
            }
        }

        return outlines
    }
}
