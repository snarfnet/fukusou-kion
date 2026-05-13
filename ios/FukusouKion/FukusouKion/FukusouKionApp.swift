import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct FukusouKionApp: App {
    @StateObject private var appModel = WeatherAppModel()

    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
                .task {
                    await appModel.refresh()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        ATTrackingManager.requestTrackingAuthorization { _ in }
                    }
                }
        }
    }
}
