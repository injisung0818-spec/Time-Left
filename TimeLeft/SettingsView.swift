import Foundation
import SwiftUI

extension Notification.Name {
    static let timeLeftAddSchedule = Notification.Name("timeLeftAddSchedule")
}

struct SettingsView: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var updateChecker: GitHubReleaseChecker
    @State private var scheduleToEdit: CountdownSchedule?
    @State private var profileToEdit: CountdownProfile?
    @State private var groupToEdit: CountdownGroup?
    @State private var isAddingSchedule = false
    @State private var isAddingProfile = false
    @State private var isAddingGroup = false

    var body: some View {
        Form {
            Section {
                Picker("현재 프로필", selection: selectedProfileBinding) {
                    ForEach(preferences.profiles) { profile in
                        Text(profile.name).tag(profile.id)
                    }
                }

                ForEach(preferences.profiles) { profile in
                    HStack(spacing: 10) {
                        Button { preferences.selectProfile(profile) } label: {
                            HStack {
                                Text(profile.name)
                                Spacer()
                                if preferences.selectedProfileID == profile.id {
                                    Text("선택됨").font(.caption).foregroundStyle(.tint)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        Button { profileToEdit = profile } label: { Image(systemName: "pencil") }
                            .buttonStyle(.borderless)
                        if !profile.isBuiltIn && preferences.profiles.count > 1 {
                            Button(role: .destructive) { preferences.deleteProfile(profile) } label: { Image(systemName: "trash") }
                                .buttonStyle(.borderless)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("프로필")
                    Spacer()
                    Button { isAddingProfile = true } label: { Image(systemName: "plus") }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("새 프로필 추가")
                }
            } footer: {
                Text("기본 프로필은 기존 일정을 보존합니다. 프로필을 바꾸면 메뉴바와 위젯도 함께 바뀝니다.")
            }

            Section {
                if preferences.groups.isEmpty {
                    Text("등록된 그룹이 없습니다. 그룹이 없는 일정은 기타로 표시됩니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(preferences.groups) { group in
                    HStack {
                        Text(group.name)
                        Spacer()
                        Button { groupToEdit = group } label: { Image(systemName: "pencil") }
                            .buttonStyle(.borderless)
                        Button(role: .destructive) { preferences.deleteGroup(group) } label: { Image(systemName: "trash") }
                            .buttonStyle(.borderless)
                    }
                }
            } header: {
                HStack {
                    Text("\(preferences.selectedProfile.name) 그룹")
                    Spacer()
                    Button { isAddingGroup = true } label: { Image(systemName: "plus") }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("새 그룹 추가")
                }
            }

            ForEach(preferences.scheduleSections()) { section in
                Section(section.name) {
                    ForEach(section.schedules) { schedule in
                        scheduleRow(schedule)
                    }
                }
            }

            Section {
                Button { isAddingSchedule = true } label: {
                    Label("새 일정 추가", systemImage: "plus")
                }
            } header: {
                Text("\(preferences.selectedProfile.name) 일정")
            } footer: {
                Text("그룹이 지정되지 않은 일정은 기타 그룹으로 표시됩니다. 하교 일정은 금요일 14:20 이후 일요일 21:00 등교 일정으로 자동 전환됩니다.")
            }

            Section("표시") {
                Picker("앱 모드", selection: $preferences.appAppearance) {
                    ForEach(AppAppearance.allCases) { appearance in Text(appearance.title).tag(appearance) }
                }
                Text("메뉴 막대 표시 방식과 단위는 각 일정의 편집 화면에서 설정할 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("앱 실행") { LaunchAtLoginToggle() }

            Section("정보") {
                HStack {
                    Text("버전")
                    Spacer()
                    Text(versionString).foregroundStyle(.secondary)
                    Text(updateChecker.status.title)
                        .font(.caption)
                        .foregroundStyle(updateChecker.status.color)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 540, height: 680)
        .navigationTitle("Time Left 설정")
        .onAppear { updateChecker.checkForLatestRelease() }
        .onChange(of: preferences.appAppearance) { appearance in
            AppearanceManager.shared.apply(appearance)
        }
        .onReceive(NotificationCenter.default.publisher(for: .timeLeftAddSchedule)) { _ in
            isAddingSchedule = true
        }
        .sheet(isPresented: $isAddingSchedule) {
            ScheduleEditorSheet(schedule: .new(), groups: preferences.groups,
                                defaultDisplayUnit: preferences.displayUnit,
                                defaultMenuBarDisplayStyle: preferences.menuBarDisplayStyle) { preferences.addSchedule($0) }
        }
        .sheet(item: $scheduleToEdit) { schedule in
            ScheduleEditorSheet(schedule: schedule, groups: preferences.groups,
                                defaultDisplayUnit: preferences.displayUnit,
                                defaultMenuBarDisplayStyle: preferences.menuBarDisplayStyle) { preferences.updateSchedule($0) }
        }
        .sheet(isPresented: $isAddingProfile) {
            ProfileEditorSheet(profile: .new()) { preferences.addProfile($0) }
        }
        .sheet(item: $profileToEdit) { profile in
            ProfileEditorSheet(profile: profile) { preferences.updateProfile($0) }
        }
        .sheet(isPresented: $isAddingGroup) {
            GroupEditorSheet(group: .new()) { preferences.addGroup($0) }
        }
        .sheet(item: $groupToEdit) { group in
            GroupEditorSheet(group: group) { preferences.updateGroup($0) }
        }
    }

    private var selectedProfileBinding: Binding<UUID> {
        Binding(get: { preferences.selectedProfileID }, set: { id in
            if let profile = preferences.profiles.first(where: { $0.id == id }) { preferences.selectProfile(profile) }
        })
    }

    @ViewBuilder private func scheduleRow(_ schedule: CountdownSchedule) -> some View {
        HStack(spacing: 10) {
            Button { preferences.selectSchedule(schedule) } label: {
                HStack {
                    Text(schedule.name)
                    Spacer()
                    if preferences.selectedScheduleID == schedule.id {
                        Text("선택됨").font(.caption).foregroundStyle(.tint)
                    }
                }
            }
            .buttonStyle(.plain)

            Button { scheduleToEdit = schedule } label: { Image(systemName: "pencil") }
                .buttonStyle(.borderless)
            if !schedule.isBuiltIn {
                Button(role: .destructive) { preferences.deleteSchedule(schedule) } label: { Image(systemName: "trash") }
                    .buttonStyle(.borderless)
            }
        }
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.1.1"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "13"
        return "\(version) (\(build))"
    }
}

private struct ScheduleEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CountdownSchedule
    let groups: [CountdownGroup]
    let defaultDisplayUnit: DisplayUnit
    let defaultMenuBarDisplayStyle: MenuBarDisplayStyle
    let onSave: (CountdownSchedule) -> Void

    init(schedule: CountdownSchedule, groups: [CountdownGroup], defaultDisplayUnit: DisplayUnit,
         defaultMenuBarDisplayStyle: MenuBarDisplayStyle, onSave: @escaping (CountdownSchedule) -> Void) {
        _draft = State(initialValue: schedule)
        self.groups = groups
        self.defaultDisplayUnit = defaultDisplayUnit
        self.defaultMenuBarDisplayStyle = defaultMenuBarDisplayStyle
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("일정 이름", text: $draft.name)
                Picker("그룹", selection: $draft.groupID) {
                    Text("기타").tag(UUID?.none)
                    ForEach(groups) { group in Text(group.name).tag(Optional(group.id)) }
                }
                Picker("카운트다운 종류", selection: $draft.kind) {
                    ForEach(CountdownKind.allCases) { kind in Text(kind.title).tag(kind) }
                }
                scheduleControls
                Picker("메뉴 막대 표시", selection: scheduleDisplayStyle) {
                    ForEach(MenuBarDisplayStyle.allCases) { style in Text(style.title).tag(style) }
                }
                if resolvedDisplayStyle == .compact {
                    Picker("표시 단위", selection: scheduleDisplayUnit) {
                        ForEach(DisplayUnit.allCases) { unit in Text(unit.title).tag(unit) }
                    }
                }
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("취소") { dismiss() }
                Button("저장") {
                    let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    draft.name = name.isEmpty ? "새 일정" : name
                    onSave(draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 440, height: 470)
    }

    private var resolvedDisplayStyle: MenuBarDisplayStyle { draft.menuBarDisplayStyle ?? defaultMenuBarDisplayStyle }
    private var scheduleDisplayStyle: Binding<MenuBarDisplayStyle> {
        Binding(get: { resolvedDisplayStyle }, set: { draft.menuBarDisplayStyle = $0 })
    }
    private var scheduleDisplayUnit: Binding<DisplayUnit> {
        Binding(get: { draft.displayUnit ?? defaultDisplayUnit }, set: { draft.displayUnit = $0 })
    }

    @ViewBuilder private var scheduleControls: some View {
        switch draft.kind {
        case .weekdayTime:
            Picker("요일", selection: $draft.weekday) {
                Text("일요일").tag(1); Text("월요일").tag(2); Text("화요일").tag(3)
                Text("수요일").tag(4); Text("목요일").tag(5); Text("금요일").tag(6); Text("토요일").tag(7)
            }
            DatePicker("시간", selection: $draft.timeOfDay, displayedComponents: .hourAndMinute)
            Toggle("매주 반복", isOn: $draft.repeatWeekly)
        case .todayTime:
            DatePicker("시간", selection: $draft.timeOfDay, displayedComponents: .hourAndMinute)
        case .specificDate, .customDate:
            DatePicker("목표 날짜", selection: $draft.selectedDate, displayedComponents: [.date, .hourAndMinute])
        case .yearEnd:
            Text("현재 연도의 마지막 순간까지 계산합니다.").foregroundStyle(.secondary)
        }
    }
}

private struct ProfileEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CountdownProfile
    let onSave: (CountdownProfile) -> Void

    init(profile: CountdownProfile, onSave: @escaping (CountdownProfile) -> Void) {
        _draft = State(initialValue: profile)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 18) {
            TextField("프로필 이름", text: $draft.name)
            HStack {
                Spacer()
                Button("취소") { dismiss() }
                Button("저장") {
                    draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "새 프로필" : draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSave(draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}

private struct GroupEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CountdownGroup
    let onSave: (CountdownGroup) -> Void

    init(group: CountdownGroup, onSave: @escaping (CountdownGroup) -> Void) {
        _draft = State(initialValue: group)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 18) {
            TextField("그룹 이름", text: $draft.name)
            HStack {
                Spacer()
                Button("취소") { dismiss() }
                Button("저장") {
                    draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "새 그룹" : draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSave(draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 360)
    }
}

private struct LaunchAtLoginToggle: View {
    @State private var isEnabled = LaunchAtLoginManager.isEnabled
    @State private var errorMessage: String?
    var body: some View {
        Toggle("로그인 시 자동 실행", isOn: Binding(get: { isEnabled }, set: { setLaunchAtLogin($0) }))
            .onAppear { isEnabled = LaunchAtLoginManager.isEnabled }
        if LaunchAtLoginManager.requiresApproval {
            Text("시스템 설정의 로그인 항목에서 Time Left 실행을 허용하세요.").font(.caption).foregroundStyle(.secondary)
        } else if let errorMessage {
            Text(errorMessage).font(.caption).foregroundStyle(.red)
        }
    }
    private func setLaunchAtLogin(_ enabled: Bool) {
        do { try LaunchAtLoginManager.setEnabled(enabled); isEnabled = LaunchAtLoginManager.isEnabled; errorMessage = nil }
        catch { isEnabled = LaunchAtLoginManager.isEnabled; errorMessage = "자동 실행 설정을 변경하지 못했습니다." }
    }
}
