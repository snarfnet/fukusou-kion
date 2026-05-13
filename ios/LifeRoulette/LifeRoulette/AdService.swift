import SwiftUI

protocol AdService {
    associatedtype Banner: View
    func banner() -> Banner
}

struct PlaceholderAdService: AdService {
    func banner() -> some View {
        Color.clear
            .frame(height: 1)
        .accessibilityHidden(true)
    }
}
