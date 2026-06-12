import SwiftUI

enum LifeEvent: String, CaseIterable, Identifiable, Hashable {
    case moving = "引っ越し"
    case birth = "出産"
    case inheritance = "相続"
    case retirement = "退職"
    case marriage = "結婚"
    case divorce = "離婚"
    case death = "家族の死亡"
    case caregiving = "介護"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .moving: "house.and.flag"
        case .birth: "figure.2.and.child.holdinghands"
        case .inheritance: "doc.text.magnifyingglass"
        case .retirement: "briefcase"
        case .marriage: "person.2"
        case .divorce: "person.crop.circle.badge.xmark"
        case .death: "cross.case"
        case .caregiving: "heart.text.square"
        }
    }

    var summary: String {
        switch self {
        case .moving: "住所、保険、年金、学校、車、郵便をまとめて確認"
        case .birth: "出生届、手当、保険、育休、医療費助成を確認"
        case .inheritance: "死亡後の届出、年金、名義変更、税務を整理"
        case .retirement: "健康保険、年金、雇用保険、住民税を確認"
        case .marriage: "婚姻届、氏名変更、住所、勤務先連絡を確認"
        case .divorce: "戸籍、氏名、住所、児童扶養手当を確認"
        case .death: "死亡届、火葬、保険、年金、公共料金を確認"
        case .caregiving: "介護認定、保険、医療、家族支援を確認"
        }
    }
}

enum ProcedureCategory: String, CaseIterable, Identifiable, Hashable {
    case residence = "住民票・戸籍"
    case insurance = "保険・年金"
    case child = "子育て"
    case tax = "税金"
    case work = "勤務先・雇用"
    case property = "財産・名義"
    case license = "免許・車"
    case utilities = "生活インフラ"
    case welfare = "福祉・介護"
    case other = "その他"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .residence: "person.text.rectangle"
        case .insurance: "checkmark.shield"
        case .child: "figure.and.child.holdinghands"
        case .tax: "yensign.square"
        case .work: "briefcase"
        case .property: "building.columns"
        case .license: "car"
        case .utilities: "bolt.horizontal"
        case .welfare: "heart.text.square"
        case .other: "tray.full"
        }
    }
}

enum Urgency: String, Hashable {
    case urgent = "至急"
    case soon = "期限近い"
    case normal = "通常"
    case confirm = "要確認"

    var color: Color {
        switch self {
        case .urgent: AppTheme.alert
        case .soon: AppTheme.warning
        case .normal: AppTheme.blue
        case .confirm: AppTheme.grayText
        }
    }
}

struct ProcedureItem: Identifiable, Hashable {
    let id: String
    let title: String
    let event: LifeEvent
    let category: ProcedureCategory
    let deadline: String
    let office: String
    let documents: [String]
    let steps: [String]
    let notes: [String]
    let online: Bool
    let urgency: Urgency
    let sourceHint: String

    var documentCountText: String {
        "\(documents.count)点"
    }
}

enum MainTab: String, CaseIterable, Hashable {
    case home = "ホーム"
    case list = "手続き"
    case deadline = "期限"
    case saved = "保存"
    case settings = "設定"

    var symbol: String {
        switch self {
        case .home: "house"
        case .list: "list.bullet.rectangle"
        case .deadline: "calendar.badge.clock"
        case .saved: "bookmark"
        case .settings: "gearshape"
        }
    }
}
