import SwiftUI

@main
struct GomiCalendarApp: App {
    @StateObject private var locationService = LocationAddressService()
    @StateObject private var scheduleStore = WasteScheduleStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationService)
                .environmentObject(scheduleStore)
        }
    }
}
