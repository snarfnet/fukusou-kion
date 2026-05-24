import Foundation

enum WisdomStore {
    static func load() -> [WisdomItem] {
        let resourceName = Locale.preferredLanguages.first?.hasPrefix("en") == true
            ? "wisdom_data_en"
            : "wisdom_data"

        let urls = [
            Bundle.main.url(forResource: resourceName, withExtension: "json"),
            Bundle.main.url(forResource: resourceName, withExtension: "json", subdirectory: "Resources"),
            Bundle.main.url(forResource: "wisdom_data", withExtension: "json"),
            Bundle.main.url(forResource: "wisdom_data", withExtension: "json", subdirectory: "Resources")
        ].compactMap { $0 }

        for url in urls {
            guard let data = try? Data(contentsOf: url) else { continue }
            if let items = try? JSONDecoder().decode([WisdomItem].self, from: data) {
                return items.sorted { $0.id < $1.id }
            }
        }

        return [
            WisdomItem(
                id: 1,
                title: "今日の小さな知恵",
                content: "急がない朝をひとつ作ると、暮らしは少し整います。",
                category: "暮らし"
            )
        ]
    }
}
