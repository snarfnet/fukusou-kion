import SwiftUI

enum AppTab: String, CaseIterable {
    case home = "ホーム"
    case memories = "思い出"
    case record = "記録"
    case calendar = "カレンダー"
    case health = "健康管理"

    var icon: String {
        switch self {
        case .home: "house"
        case .memories: "camera"
        case .record: "plus.square"
        case .calendar: "calendar"
        case .health: "waveform.path.ecg"
        }
    }
}

enum RecordKind: String, CaseIterable {
    case meal = "食事"
    case medicine = "薬"
    case weight = "体重"
    case symptom = "症状"
    case vet = "通院"
    case photo = "写真"
    case walk = "散歩"

    var icon: String {
        switch self {
        case .meal: "takeoutbag.and.cup.and.straw"
        case .medicine: "pills"
        case .weight: "waveform.path.ecg"
        case .symptom: "cross.case"
        case .vet: "stethoscope"
        case .photo: "camera"
        case .walk: "pawprint"
        }
    }

    var options: [String] {
        switch self {
        case .meal: ["完食", "少なめ", "多め", "食べない"]
        case .medicine: ["飲ませた", "あとで通知", "飲ませ忘れ", "吐き戻しあり"]
        case .weight: ["4.8kg", "4.7kg", "4.9kg", "あとで入力"]
        case .symptom: ["下痢", "嘔吐", "咳", "かゆみ", "食欲低下", "元気なし"]
        case .vet: ["定期診察", "ワクチン", "検査", "相談"]
        case .photo: ["思い出", "症状メモ", "成長記録", "共有用"]
        case .walk: ["元気", "ゆっくり", "短め", "排泄メモあり"]
        }
    }

    var notePlaceholder: String {
        switch self {
        case .meal: "例: 朝ごはんを半分残した"
        case .medicine: "例: 20:00にフィラリア予防薬"
        case .weight: "例: 食後に測定。前回より少し増えた"
        case .symptom: "例: 夜に短い咳が2回。元気はある"
        case .vet: "例: 青葉動物病院。食欲低下を相談"
        case .photo: "例: 朝のひなたで撮影。元気そう"
        case .walk: "例: 35分。帰宅後も元気"
        }
    }
}

struct CareTask: Identifiable {
    let id = UUID()
    let owner: String
    let title: String
    let icon: String
    var done: Bool
}

struct TimelineEntry: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let time: String
}

struct AppState {
    var selectedTab: AppTab = .home
    var selectedRecordKind: RecordKind = .meal
    var selectedRecordOption: String = "完食"
    var recordNote: String = ""
    var showingPlus = false
    var showingPetProfile = false
    var showingHospital = false
    var showingSafetyCard = false
    var showingFamily = false
    var showingInsurance = false
    var showingVet = false
    var showingDetail = false
    var detailTitle = ""
    var detailText = ""
    var calendarFormOpen = false
    var calendarKind = "通院"
    var calendarNote = ""
    var tasks: [CareTask] = [
        CareTask(owner: "ママ", title: "朝ごはん 完了", icon: "checkmark", done: true),
        CareTask(owner: "パパ", title: "薬 20:00", icon: "pills", done: false),
        CareTask(owner: "さくら", title: "夕方のおさんぽ", icon: "pawprint", done: false)
    ]
    var timeline: [TimelineEntry] = [
        TimelineEntry(icon: "pawprint", title: "おさんぽ", detail: "7:30・35分・元気", time: "今日"),
        TimelineEntry(icon: "takeoutbag.and.cup.and.straw", title: "ごはん", detail: "7:00・完食・いつものフード", time: "今日"),
        TimelineEntry(icon: "pills", title: "おくすり", detail: "フィラリア予防薬 20:00", time: "予定")
    ]
}
