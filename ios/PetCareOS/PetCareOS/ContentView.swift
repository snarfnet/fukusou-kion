import SwiftUI

struct ContentView: View {
    @State private var state = AppState()

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(red: 0.985, green: 0.962, blue: 0.925), Color(red: 0.929, green: 0.960, blue: 0.934)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                PetHeader(title: title, state: $state)

                ScrollView(showsIndicators: false) {
                    Group {
                        switch state.selectedTab {
                        case .home:
                            HomeView(state: $state)
                        case .memories:
                            MemoriesView(state: $state)
                        case .record:
                            RecordView(state: $state)
                        case .calendar:
                            CalendarView(state: $state)
                        case .health:
                            HealthView(state: $state)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, state.selectedTab == .home ? 0 : 12)
                    .padding(.bottom, 110)
                }
            }

            BottomTabs(state: $state)
        }
        .foregroundStyle(PetTheme.ink)
        .sheet(isPresented: $state.showingPlus) { PlusSheet() }
        .sheet(isPresented: $state.showingPetProfile) { PetProfileSheet() }
        .sheet(isPresented: $state.showingHospital) { HospitalSheet() }
        .sheet(isPresented: $state.showingSafetyCard) { SafetyCardSheet() }
        .sheet(isPresented: $state.showingFamily) { FamilySheet() }
        .sheet(isPresented: $state.showingInsurance) { InsuranceSheet() }
        .sheet(isPresented: $state.showingVet) { VetSheet() }
        .sheet(isPresented: $state.showingDetail) {
            DetailSheet(title: state.detailTitle, text: state.detailText)
        }
    }

    private var title: String {
        state.selectedTab == .home ? "モカ" : state.selectedTab.rawValue
    }
}

struct HomeView: View {
    @Binding var state: AppState

    var body: some View {
        VStack(spacing: 14) {
            hero
            quickActions
            memoryCard
            timeline
            miniPanels
            familyTasks
        }
    }

    private var hero: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let imageSize = min(max(width * 0.38, 118), 152)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 11) {
                    SectionKicker(text: "おはようございます")
                    Text("モカとの今日も、すてきな1日になりますように。")
                        .font(.system(size: 25, weight: .bold))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("6月9日 火曜日")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PetTheme.muted)
                    Button {
                        state.selectedRecordKind = .meal
                        state.selectedTab = .record
                    } label: {
                        Label("今日の様子を記録", systemImage: "plus")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(PetTheme.coral)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .padding(.horizontal, 13)
                            .frame(height: 40)
                            .background(.white.opacity(0.72))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(PetTheme.coral.opacity(0.35)))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image("MokaHomeHero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.78), lineWidth: 4))
                    .shadow(color: Color.black.opacity(0.06), radius: 14, y: 8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .frame(width: width, height: proxy.size.height)
            .background(.white.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
        .frame(height: 238)
    }

    private var quickActions: some View {
        HStack(spacing: 7) {
            quick("記録する", "plus.square", .meal)
            quick("思い出", "camera", nil)
            quick("ごはん", "takeoutbag.and.cup.and.straw", .meal)
            quick("おさんぽ", "pawprint", .walk)
            quick("おくすり", "pills", .medicine)
        }
    }

    private func quick(_ title: String, _ icon: String, _ kind: RecordKind?) -> some View {
        Button {
            if let kind {
                state.selectedRecordKind = kind
                state.selectedTab = .record
            } else {
                state.selectedTab = .memories
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(PetTheme.coral)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 82)
            .background(.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(PetTheme.line))
        }
        .buttonStyle(.plain)
    }

    private var memoryCard: some View {
        Button {
            state.detailTitle = "春のおさんぽ"
            state.detailText = "写真、日付、体調メモをまとめて確認できます。"
            state.showingDetail = true
        } label: {
            HStack(spacing: 12) {
                Image("MokaSpringMemory")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 132, height: 124)
                    .clipped()
                VStack(alignment: .leading, spacing: 8) {
                    Text("思い出アルバム")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(PetTheme.coral)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(PetTheme.coral.opacity(0.12))
                        .clipShape(Capsule())
                    Text("春のおさんぽ")
                        .font(.headline.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text("満開の花の下で、うれしそうなモカの笑顔。")
                        .font(.caption)
                        .foregroundStyle(PetTheme.muted)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(PetTheme.ink)
            }
            .background(.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(PetTheme.line))
        }
        .buttonStyle(.plain)
    }

    private var timeline: some View {
        SoftCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    SectionKicker(text: "最近の記録")
                    Text("生活と体調")
                        .font(.title3.weight(.bold))
                }
                Spacer()
                Button("すべて見る") {
                    state.selectedTab = .record
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PetTheme.coral)
            }
            VStack(spacing: 0) {
                ForEach(Array(state.timeline.prefix(3).enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 10) {
                        IconBubble(systemName: entry.icon)
                        VStack(alignment: .leading) {
                            Text(entry.title)
                                .font(.subheadline.weight(.bold))
                            Text(entry.detail)
                                .font(.caption)
                                .foregroundStyle(PetTheme.muted)
                        }
                        Spacer()
                        Text(entry.time)
                            .font(.caption)
                            .foregroundStyle(PetTheme.muted)
                    }
                    .padding(.vertical, 10)
                    Divider().opacity(index == min(state.timeline.count, 3) - 1 ? 0 : 1)
                }
            }
        }
    }

    private var miniPanels: some View {
        HStack(spacing: 10) {
            mini("おくすり", "フィラリア予防薬", "今日 20:00", "記録する") {
                state.selectedRecordKind = .medicine
                state.selectedTab = .record
            }
            mini("通院予定", "定期検診", "6月18日 10:30", "詳細を見る") {
                state.selectedTab = .calendar
            }
        }
    }

    private func mini(_ kicker: String, _ title: String, _ subtitle: String, _ action: String, run: @escaping () -> Void) -> some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionKicker(text: kicker)
                Text(title)
                    .font(.headline.weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(PetTheme.muted)
                Button(action, action: run)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PetTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.72))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var familyTasks: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionKicker(text: "家族のメンバー")
                Text("今日の担当")
                    .font(.title3.weight(.bold))
                Text("誰が何を済ませたか、家族で同じ画面を見られます。")
                    .font(.caption)
                    .foregroundStyle(PetTheme.muted)

                ForEach($state.tasks) { $task in
                    Button {
                        task.done.toggle()
                    } label: {
                        HStack(spacing: 10) {
                            IconBubble(systemName: task.done ? "checkmark" : task.icon)
                            Text(task.owner)
                                .font(.subheadline.weight(.bold))
                            Text(task.title)
                                .font(.caption)
                                .foregroundStyle(PetTheme.muted)
                            Spacer()
                        }
                        .padding(10)
                        .background(task.done ? PetTheme.sage.opacity(0.14) : .white.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    state.showingFamily = true
                } label: {
                    Label("メンバーを追加", systemImage: "person.badge.plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(PetTheme.coral)
                }
            }
        }
    }
}
