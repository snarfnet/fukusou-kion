import Foundation
import SwiftData

@Model
final class PackingList {
    var id: UUID
    var title: String
    var scene: String
    var createdAt: Date
    var lastUsedAt: Date
    var isFavorite: Bool
    var isTodayList: Bool

    @Relationship(deleteRule: .cascade, inverse: \PackingItem.list)
    var items: [PackingItem]

    init(
        id: UUID = UUID(),
        title: String,
        scene: String,
        createdAt: Date = .now,
        lastUsedAt: Date = .now,
        isFavorite: Bool = true,
        isTodayList: Bool = false,
        items: [PackingItem] = []
    ) {
        self.id = id
        self.title = title
        self.scene = scene
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.isFavorite = isFavorite
        self.isTodayList = isTodayList
        self.items = items
    }

    var checkedCount: Int {
        items.filter(\.isChecked).count
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(checkedCount) / Double(items.count)
    }

    var isComplete: Bool {
        !items.isEmpty && checkedCount == items.count
    }

    func replaceItems(with names: [String]) {
        items = names.enumerated().map { index, name in
            let item = PackingItem(name: name, order: index)
            item.list = self
            return item
        }
    }
}

@Model
final class PackingItem {
    var id: UUID
    var name: String
    var isChecked: Bool
    var order: Int
    var list: PackingList?

    init(id: UUID = UUID(), name: String, isChecked: Bool = false, order: Int = 0) {
        self.id = id
        self.name = name
        self.isChecked = isChecked
        self.order = order
    }
}

@Model
final class ForgottenRecord {
    var id: UUID
    var itemName: String
    var count: Int
    var updatedAt: Date

    init(id: UUID = UUID(), itemName: String, count: Int = 1, updatedAt: Date = .now) {
        self.id = id
        self.itemName = itemName
        self.count = count
        self.updatedAt = updatedAt
    }
}

struct PackingTemplate: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let symbol: String
    let tintName: String
    let items: [String]

    static let defaults: [PackingTemplate] = [
        PackingTemplate(title: "仕事", symbol: "briefcase.fill", tintName: "olive", items: ["財布", "鍵", "スマホ", "社員証", "イヤホン", "充電器", "書類"]),
        PackingTemplate(title: "学校", symbol: "graduationcap.fill", tintName: "blue", items: ["財布", "鍵", "学生証", "教科書", "ノート", "筆箱", "体操服"]),
        PackingTemplate(title: "旅行", symbol: "airplane.departure", tintName: "coral", items: ["財布", "鍵", "スマホ", "充電器", "着替え", "下着", "チケット", "保険証"]),
        PackingTemplate(title: "ジム", symbol: "figure.strengthtraining.traditional", tintName: "mint", items: ["会員証", "タオル", "着替え", "シューズ", "飲み物", "イヤホン"]),
        PackingTemplate(title: "病院", symbol: "cross.case.fill", tintName: "rose", items: ["診察券", "保険証", "お薬手帳", "財布", "マスク"])
    ]
}
