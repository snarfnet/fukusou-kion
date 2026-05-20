import SwiftUI
import UIKit

struct PhotoTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let category: TemplateCategory
    let imageName: String?
    let isPaid: Bool
    let defaultCircleX: CGFloat
    let defaultCircleY: CGFloat
    let defaultCircleSize: CGFloat
    let defaultTitleText: String
    let defaultSubtitleText: String
    let defaultFilter: TemplateFilter
    let accent: Color
    let mood: TemplateMood

    static func == (lhs: PhotoTemplate, rhs: PhotoTemplate) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum TemplateCategory: String {
    case free = "無料"
    case eventPack = "思い出行事パック"
    case secondPack = "思い出行事パック2"
}

enum TemplatePack: String, Identifiable, CaseIterable {
    case eventPack
    case secondPack

    var id: String { rawValue }

    var productID: String {
        switch self {
        case .eventPack:
            return TemplateLibrary.eventPackProductID
        case .secondPack:
            return TemplateLibrary.secondPackProductID
        }
    }

    var title: String {
        switch self {
        case .eventPack:
            return "思い出行事パック"
        case .secondPack:
            return "思い出行事パック2"
        }
    }

    var description: String {
        switch self {
        case .eventPack:
            return "体育祭、文化祭、例の遊園地、林間学校、楽しい遠足の5テンプレートを解放します。"
        case .secondPack:
            return "明治維新、本気の登山、例のユニバ、イ〇〇の物置、異世界の5テンプレートを解放します。"
        }
    }

    var templateNames: [String] {
        switch self {
        case .eventPack:
            return ["体育祭", "文化祭", "例の遊園地", "林間学校", "楽しい遠足"]
        case .secondPack:
            return ["明治維新", "本気の登山", "例のユニバ", "イ〇〇の物置", "異世界"]
        }
    }
}

enum TemplateFilter: String, CaseIterable, Identifiable {
    case normal = "標準"
    case sepia = "セピア"
    case monochrome = "白黒"

    var id: String { rawValue }
}

enum TemplateMood {
    case graduation
    case trip
    case postwar
    case sports
    case festival
    case amusement
    case forest
    case excursion
    case meiji
    case mountain
    case uniba
    case storage
    case isekai
}

struct AlbumText {
    var year: String
    var title: String
    var schoolName: String
    var grade: String
    var classroom: String
    var absenteeName: String
    var comment: String

    var titleLine: String {
        [year, title].filter { !$0.isEmpty }.joined(separator: "　")
    }

    var schoolLine: String {
        let gradePart = grade.isEmpty ? "" : "\(grade)年"
        let classPart = classroom.isEmpty ? "" : "\(classroom)組"
        let classLine = gradePart + classPart
        return [schoolName, classLine].filter { !$0.isEmpty }.joined(separator: "　")
    }

    static let standard = AlbumText(
        year: "令和6年度",
        title: "卒業記念",
        schoolName: "〇〇市立〇〇中学校",
        grade: "3",
        classroom: "B",
        absenteeName: "",
        comment: ""
    )
}

struct EditorState {
    var text = AlbumText.standard
    var circleCenter = CGPoint(x: 0.78, y: 0.08)
    var circleSize: CGFloat = 0.18
    var photoScale: CGFloat = 1.0
    var photoOffset = CGSize.zero
    var photoRotation: Angle = .zero
    var borderWidth: CGFloat = 12
    var showsBorder = true
    var showsShadow = true
    var filter: TemplateFilter = .normal

    mutating func applyDefaults(from template: PhotoTemplate) {
        circleCenter = CGPoint(x: template.defaultCircleX, y: template.defaultCircleY)
        circleSize = template.defaultCircleSize
        filter = template.defaultFilter
        let parts = template.defaultTitleText.components(separatedBy: "　")
        text.year = parts.first ?? text.year
        text.title = parts.dropFirst().joined(separator: "　")
        if text.title.isEmpty {
            text.title = template.defaultTitleText
        }
    }
}

enum TemplateLibrary {
    static let eventPackProductID = "omoide_event_pack"
    static let secondPackProductID = "absentee_frame_pack_2"

    static let templates: [PhotoTemplate] = [
        PhotoTemplate(
            id: "standard_graduation",
            name: "標準卒アル",
            category: .free,
            imageName: "template_standard_graduation",
            isPaid: false,
            defaultCircleX: 0.885,
            defaultCircleY: 0.157,
            defaultCircleSize: 0.175,
            defaultTitleText: "令和6年度　卒業記念",
            defaultSubtitleText: "〇〇市立〇〇中学校　3年B組",
            defaultFilter: .normal,
            accent: .pink,
            mood: .graduation
        ),
        PhotoTemplate(
            id: "school_trip",
            name: "修学旅行",
            category: .free,
            imageName: "template_school_trip",
            isPaid: false,
            defaultCircleX: 0.885,
            defaultCircleY: 0.158,
            defaultCircleSize: 0.20,
            defaultTitleText: "令和6年度　修学旅行記念",
            defaultSubtitleText: "〇〇市立〇〇中学校　3年B組",
            defaultFilter: .normal,
            accent: .blue,
            mood: .trip
        ),
        PhotoTemplate(
            id: "postwar",
            name: "戦後まもない",
            category: .free,
            imageName: "template_postwar",
            isPaid: false,
            defaultCircleX: 0.902,
            defaultCircleY: 0.155,
            defaultCircleSize: 0.155,
            defaultTitleText: "昭和24年度　卒業記念写真",
            defaultSubtitleText: "〇〇町立〇〇中学校　第3学年",
            defaultFilter: .monochrome,
            accent: .brown,
            mood: .postwar
        ),
        PhotoTemplate(id: "sports_day", name: "体育祭", category: .eventPack, imageName: "template_sports_day", isPaid: true, defaultCircleX: 0.893, defaultCircleY: 0.135, defaultCircleSize: 0.165, defaultTitleText: "令和6年度　体育祭記念", defaultSubtitleText: "〇〇市立〇〇中学校　3年B組", defaultFilter: .normal, accent: .red, mood: .sports),
        PhotoTemplate(id: "culture_festival", name: "文化祭", category: .eventPack, imageName: "template_culture_festival", isPaid: true, defaultCircleX: 0.895, defaultCircleY: 0.15, defaultCircleSize: 0.165, defaultTitleText: "令和6年度　文化祭記念", defaultSubtitleText: "〇〇高校　2年A組", defaultFilter: .normal, accent: .purple, mood: .festival),
        PhotoTemplate(id: "amusement_park", name: "例の遊園地", category: .eventPack, imageName: "template_amusement_park", isPaid: true, defaultCircleX: 0.875, defaultCircleY: 0.15, defaultCircleSize: 0.18, defaultTitleText: "令和6年度　集合写真", defaultSubtitleText: "〇〇市立〇〇中学校　3年B組", defaultFilter: .normal, accent: .orange, mood: .amusement),
        PhotoTemplate(id: "forest_school", name: "林間学校", category: .eventPack, imageName: "template_forest_school", isPaid: true, defaultCircleX: 0.87, defaultCircleY: 0.145, defaultCircleSize: 0.165, defaultTitleText: "令和6年度　林間学校", defaultSubtitleText: "〇〇市立〇〇中学校　3年B組", defaultFilter: .normal, accent: .green, mood: .forest),
        PhotoTemplate(id: "excursion", name: "楽しい遠足", category: .eventPack, imageName: "template_excursion", isPaid: true, defaultCircleX: 0.89, defaultCircleY: 0.145, defaultCircleSize: 0.17, defaultTitleText: "令和6年度　遠足記念", defaultSubtitleText: "〇〇市立〇〇中学校　3年B組", defaultFilter: .normal, accent: .teal, mood: .excursion),
        PhotoTemplate(id: "meiji_restoration", name: "明治維新", category: .secondPack, imageName: "template_meiji_restoration", isPaid: true, defaultCircleX: 0.89, defaultCircleY: 0.16, defaultCircleSize: 0.175, defaultTitleText: "明治元年　維新記念", defaultSubtitleText: "〇〇藩士一同", defaultFilter: .monochrome, accent: .gray, mood: .meiji),
        PhotoTemplate(id: "serious_mountain", name: "本気の登山", category: .secondPack, imageName: "template_serious_mountain", isPaid: true, defaultCircleX: 0.89, defaultCircleY: 0.145, defaultCircleSize: 0.17, defaultTitleText: "令和6年度　本気の登山", defaultSubtitleText: "〇〇山岳部", defaultFilter: .normal, accent: .indigo, mood: .mountain),
        PhotoTemplate(id: "uniba_like", name: "例のユニバ", category: .secondPack, imageName: "template_uniba_like", isPaid: true, defaultCircleX: 0.875, defaultCircleY: 0.15, defaultCircleSize: 0.18, defaultTitleText: "令和6年度　集合写真", defaultSubtitleText: "〇〇市立〇〇中学校　3年B組", defaultFilter: .normal, accent: .blue, mood: .uniba),
        PhotoTemplate(id: "storage_roof", name: "イ〇〇の物置", category: .secondPack, imageName: "template_storage_roof", isPaid: true, defaultCircleX: 0.88, defaultCircleY: 0.18, defaultCircleSize: 0.20, defaultTitleText: "令和6年度　物置記念", defaultSubtitleText: "〇〇高校　全員集合", defaultFilter: .normal, accent: .mint, mood: .storage),
        PhotoTemplate(id: "isekai", name: "異世界", category: .secondPack, imageName: "template_isekai", isPaid: true, defaultCircleX: 0.875, defaultCircleY: 0.155, defaultCircleSize: 0.18, defaultTitleText: "異世界元年　召喚記念", defaultSubtitleText: "王立〇〇学院", defaultFilter: .normal, accent: .purple, mood: .isekai)
    ]
}

enum EditorTool: String, CaseIterable, Identifiable {
    case photo = "写真追加"
    case circle = "丸窓調整"
    case text = "文字入力"
    case filter = "フィルター"
    case save = "保存"

    var id: String { rawValue }
}
