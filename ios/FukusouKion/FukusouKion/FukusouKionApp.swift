import SwiftUI

@main
struct FukusouKionApp: App {
    @StateObject private var appModel = WeatherAppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
                .task {
                    AdService.shared.start()
                    await appModel.refresh()
                }
        }
    }
}
