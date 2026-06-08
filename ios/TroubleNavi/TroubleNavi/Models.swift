import Foundation

struct TroubleCasePayload: Decodable {
    let version: String
    let count: Int
    let purpose: String
    let cases: [TroubleCase]
}

struct TroubleCase: Decodable, Identifiable, Hashable {
    let id: String
    let category: String
    let urgency: Urgency
    let title: String
    let summary: String
    let steps: [String]
    let avoid: [String]
    let evidence: [String]
    let contacts: [String]
    let memo: [String]
    let sourceKeys: [String]
    let tags: [String]
    let legalBoundary: String
}

enum Urgency: String, Decodable, CaseIterable, Hashable {
    case high = "高"
    case medium = "中"
    case low = "低"

    var title: String {
        switch self {
        case .high: return "緊急度 高"
        case .medium: return "緊急度 中"
        case .low: return "緊急度 低"
        }
    }
}

struct SourceLink: Identifiable, Hashable {
    let id: String
    let title: String
    let url: URL
}

enum SourceDirectory {
    static let links: [String: SourceLink] = [
        "courtsDivorce": .init(id: "courtsDivorce", title: "裁判所: 夫婦関係調整など", url: URL(string: "https://www.courts.go.jp/saiban/syurui/fuufu/index.html")!),
        "mojParenting": .init(id: "mojParenting", title: "法務省: 親子交流", url: URL(string: "https://www.moj.go.jp/MINJI/minji07_00017.html")!),
        "houterasu": .init(id: "houterasu", title: "法テラス", url: URL(string: "https://www.houterasu.or.jp/index.html")!),
        "mlitMansionRules": .init(id: "mlitMansionRules", title: "国土交通省: マンション標準管理規約", url: URL(string: "https://www.mlit.go.jp/jutakukentiku/house/mansionkiyaku.html")!),
        "mlitMansionManage": .init(id: "mlitMansionManage", title: "国土交通省: マンション管理", url: URL(string: "https://www.mlit.go.jp/jutakukentiku/house/jutakukentiku_house_tk5_000052.html")!),
        "mankan": .init(id: "mankan", title: "マンション管理センター", url: URL(string: "https://www.mankan.or.jp/")!),
        "envWaste": .init(id: "envWaste", title: "環境省: 廃棄物・リサイクル", url: URL(string: "https://www.env.go.jp/recycle/waste/index.html")!),
        "consumer": .init(id: "consumer", title: "消費者庁: 消費者ホットライン188", url: URL(string: "https://www.caa.go.jp/policies/application/inquiry/")!),
        "labor": .init(id: "labor", title: "厚生労働省: 総合労働相談コーナー", url: URL(string: "https://www.mhlw.go.jp/general/seido/chihou/kaiketu/soudan.html")!),
        "harassment": .init(id: "harassment", title: "厚生労働省: 職場のハラスメント", url: URL(string: "https://www.mhlw.go.jp/stf/seisakunitsuite/bunya/koyou_roudou/koyoukintou/seisaku06/index.html")!),
        "internet": .init(id: "internet", title: "法務省: インターネット人権相談", url: URL(string: "https://www.moj.go.jp/JINKEN/jinken88.html")!),
        "cyber": .init(id: "cyber", title: "警察庁: サイバー警察局", url: URL(string: "https://www.npa.go.jp/bureau/cyber/")!),
        "phishing": .init(id: "phishing", title: "警察庁: フィッシング対策", url: URL(string: "https://www.npa.go.jp/bureau/cyber/countermeasures/phishing.html")!),
        "supportFraud": .init(id: "supportFraud", title: "警察庁: サポート詐欺対策", url: URL(string: "https://www.npa.go.jp/bureau/cyber/countermeasures/support-fraud.html")!),
        "spam": .init(id: "spam", title: "迷惑メール相談センター", url: URL(string: "https://www.dekyo.or.jp/soudan/contents/")!),
        "accident": .init(id: "accident", title: "国土交通省: 交通事故にあったら", url: URL(string: "https://www.mlit.go.jp/jidosha/jibaiseki/accident/correspondence/index.html")!),
        "jsdc": .init(id: "jsdc", title: "自動車安全運転センター", url: URL(string: "https://www.jsdc.or.jp/certificate/tabid/112/Default.aspx")!),
        "lost": .init(id: "lost", title: "警察庁: 落とし物", url: URL(string: "https://www.npa.go.jp/bureau/soumu/ishitsubutsu/ishitsu-todokedekensaku.html")!),
        "kokusenRent": .init(id: "kokusenRent", title: "国民生活センター: 賃貸住宅の原状回復", url: URL(string: "https://www.kokusen.go.jp/soudan_topics/data/chintai.html")!)
    ]
}
