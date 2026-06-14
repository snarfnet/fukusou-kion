import Foundation
import SwiftUI
import UIKit

struct CellArtSettings: Equatable {
    var width: Int = 120
    var paletteSize: Int = 64
    var cellSize: Double = 10
    var showGrid: Bool = false
    var trimBackground: Bool = true
    var dither: Bool = true
    var contrastBoost: Double = 1.10
    var saturationBoost: Double = 1.04
}

struct PixelCell: Identifiable, Equatable {
    let id = UUID()
    let row: Int
    let column: Int
    let color: CellColor
}

struct CellColor: Hashable, Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var swiftUIColor: Color {
        Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }

    var hex: String {
        String(format: "%02X%02X%02X", red, green, blue)
    }
}

struct CellArtDocument {
    let width: Int
    let height: Int
    let cells: [PixelCell]
    let palette: [CellColor]

    var estimatedCellCount: Int {
        width * height
    }
}

struct ExportedWorkbook: Identifiable {
    let id = UUID()
    let url: URL
    let cellCount: Int
    let paletteCount: Int
}
