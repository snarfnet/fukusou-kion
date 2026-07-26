import SwiftUI

enum DNBStyle: String, CaseIterable, Identifiable {
    case liquid = "LIQUID"
    case jungle = "JUNGLE"
    case dark = "DARK"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .liquid: "広がるパッドと滑らかなベース"
        case .jungle: "細かく刻むブレイクビーツ"
        case .dark: "重いサブベースと硬いドラム"
        }
    }

    var color: Color {
        switch self {
        case .liquid: Color(red: 0.45, green: 0.76, blue: 0.95)
        case .jungle: Color(red: 0.96, green: 0.66, blue: 0.27)
        case .dark: Color(red: 0.67, green: 0.43, blue: 0.91)
        }
    }
}

enum TransformState: Equatable {
    case empty
    case ready
    case rendering(Double)
    case complete
    case failed(String)
}

