import Foundation
import CoreLocation

struct Era: Identifiable, Equatable {
    let id = UUID()
    let year: String
    let story: String
}

struct NearbyStory: Identifiable {
    let id = UUID()
    let kanji: String
    let category: String
    let title: String
    let place: String
    let distance: Int
}

struct PlaceStory: Identifiable, Hashable {
    let id: String
    let kanji: String
    let name: String
    let area: String
    let latitude: Double
    let longitude: Double
    let headline: String
    let introduction: String
    let foundedLabel: String
    let oldName: String
    let eras: [Era]
    let nearby: [NearbyStory]

    static func == (lhs: PlaceStory, rhs: PlaceStory) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension PlaceStory {
    static let featured: [PlaceStory] = [
        .init(id: "asakusa", kanji: "浅草", name: "Asakusa", area: "Taitō, Tokyo", latitude: 35.7148, longitude: 139.7967,
              headline: "A temple town shaped\nby water and pilgrims.", introduction: "Long before neon signs and souvenir shops, Asakusa grew around Sensō-ji—Tokyo’s oldest temple. Its name may describe the shallow grasses that once lined the nearby river.", foundedLabel: "628", oldName: "浅草村", eras: Era.asakusa, nearby: NearbyStory.asakusa),
        .init(id: "shibuya", kanji: "渋谷", name: "Shibuya", area: "Shibuya, Tokyo", latitude: 35.6595, longitude: 139.7005,
              headline: "A valley crossing where\nroads, rails and people meet.", introduction: "Shibuya sits in a natural valley carved by the Shibuya River. What looks like a vertical city today grew from roads, farmland and a small station opened in 1885.", foundedLabel: "1885", oldName: "渋谷村", eras: [.init(year:"Today",story:"Railways, fashion and nightlife converge above the old river valley."),.init(year:"1964",story:"The Tokyo Olympics accelerated road building and reshaped the district."),.init(year:"1885",story:"A small railway station opened among fields at the bottom of the valley."),.init(year:"Edo",story:"Villages and farm roads followed the folds of the surrounding hills.")], nearby: [.init(kanji:"忠",category:"LOCAL MEMORY · 2 MIN",title:"The dog who waited at the station",place:"Hachikō Square",distance:90),.init(kanji:"川",category:"LOST LANDSCAPE · 5 MIN",title:"The river beneath the city",place:"Shibuya River",distance:340)]),
        .init(id: "gion", kanji: "祇園", name: "Gion", area: "Higashiyama, Kyoto", latitude: 35.0037, longitude: 135.7785,
              headline: "A shrine town where\nperformance became tradition.", introduction: "Gion developed beside Yasaka Shrine as teahouses welcomed pilgrims and travelers. Its narrow streets still preserve the scale of a premodern entertainment district.", foundedLabel: "656", oldName: "祇園町", eras: [.init(year:"Today",story:"Residents, craftspeople and performers share a neighborhood visited from around the world."),.init(year:"1950",story:"Postwar preservation efforts began protecting Gion’s historic townscape."),.init(year:"1700",story:"Teahouses and performance culture flourished near the shrine approaches."),.init(year:"656",story:"Tradition places the origin of Yasaka Shrine in the seventh century.")], nearby: [.init(kanji:"舞",category:"LIVING CULTURE · 3 MIN",title:"A street shaped by performance",place:"Hanamikoji",distance:180),.init(kanji:"水",category:"LANDSCAPE · 6 MIN",title:"The stream beside old teahouses",place:"Shirakawa",distance:420)]),
        .init(id: "kamakura", kanji: "鎌倉", name: "Kamakura", area: "Kanagawa", latitude: 35.3192, longitude: 139.5467,
              headline: "A seaside capital protected\nby hills and narrow passes.", introduction: "Kamakura’s ring of steep hills and open sea helped make it the seat of Japan’s first warrior government. Old paths and temple valleys remain embedded in the modern town.", foundedLabel: "1185", oldName: "鎌倉郡", eras: [.init(year:"Today",story:"A coastal town where daily life overlaps with temples and medieval paths."),.init(year:"1923",story:"The Great Kantō Earthquake damaged many historic buildings across Kamakura."),.init(year:"1333",story:"The Kamakura government fell after forces entered through the surrounding passes."),.init(year:"1185",story:"The emerging warrior government established its base in this naturally defended landscape.")], nearby: [.init(kanji:"段",category:"HISTORIC WAY · 3 MIN",title:"The raised approach to the shrine",place:"Dankazura",distance:210),.init(kanji:"谷",category:"LANDSCAPE · 7 MIN",title:"Why Kamakura has so many valleys",place:"Yato landscape",distance:500)]),
        .init(id: "nagasaki", kanji: "長崎", name: "Nagasaki", area: "Nagasaki", latitude: 32.7503, longitude: 129.8779,
              headline: "A port city written across\nhillsides and cultures.", introduction: "Nagasaki’s deep harbor connected Japan with overseas trade. Chinese, Dutch and Japanese communities left distinct layers in its streets, food and architecture.", foundedLabel: "1571", oldName: "長崎村", eras: [.init(year:"Today",story:"Trams thread together a city whose neighborhoods climb steep harbor hills."),.init(year:"1945",story:"The atomic bombing caused immense loss; the city rebuilt while preserving testimony and memory."),.init(year:"1641",story:"Dutch traders were confined to the artificial island of Dejima."),.init(year:"1571",story:"The port opened to international trade and the settlement grew rapidly.")], nearby: [.init(kanji:"出",category:"TRADE · 4 MIN",title:"Japan’s window to the Dutch world",place:"Dejima",distance:280),.init(kanji:"橋",category:"CITY STORY · 6 MIN",title:"The stone bridge shaped like spectacles",place:"Meganebashi",distance:440)])
    ]
}

extension Era {
    static let asakusa: [Era] = [
        .init(year: "Today", story: "A lively neighborhood where temple culture, craft shops and everyday Tokyo meet."),
        .init(year: "1923", story: "The Great Kantō Earthquake transformed the district. Sensō-ji’s grounds became a refuge for local residents."),
        .init(year: "1849", story: "In late Edo, Asakusa was the city’s great entertainment quarter—packed with pilgrims, performers and street vendors."),
        .init(year: "628", story: "Temple tradition says two fishermen found a statue of Kannon in the Sumida River, leading to Sensō-ji’s founding.")
    ]
}

extension NearbyStory {
    static let asakusa: [NearbyStory] = [
        .init(kanji: "雷", category: "LANDMARK · 2 MIN", title: "The gate named after thunder", place: "Kaminarimon", distance: 120),
        .init(kanji: "舟", category: "LOST LANDSCAPE · 5 MIN", title: "Where Edo’s boats once landed", place: "Sumida riverbank", distance: 350),
        .init(kanji: "噺", category: "CULTURE · 7 MIN", title: "A district built for storytellers", place: "Asakusa entertainment quarter", distance: 480)
    ]
}
