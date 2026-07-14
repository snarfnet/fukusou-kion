import SwiftUI

enum AppRoute: Hashable {
    case register, cases, caseDetail(UUID), police, settings, emergency, found
}

struct AppRouterView: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView { path.append($0) }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .register: RegistrationWizardView { id in path = [.caseDetail(id)] }
                    case .cases: CaseListView { path.append(.caseDetail($0)) }
                    case .caseDetail(let id): CaseDetailView(caseID: id)
                    case .police: PoliceBoxSearchView()
                    case .settings: SettingsView()
                    case .emergency: EmergencyGuideView()
                    case .found: FoundSomethingView()
                    }
                }
        }
        .tint(.brandBlue)
    }
}

extension Color {
    static let brandBlue = Color(red: 0.05, green: 0.23, blue: 0.48)
    static let supportBlue = Color(red: 0.17, green: 0.55, blue: 0.86)
}

