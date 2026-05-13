import SwiftUI

@main
struct FukusouKionApp: App {
    @StateObject private var appModel = WeatherAppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
                .environmentObject(AdService.shared)
                .task {
                    await AdService.shared.start()
                    await appModel.refresh()
                }
        }
    }
}
