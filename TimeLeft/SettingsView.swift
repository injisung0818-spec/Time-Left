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
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.1.2"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "14"
        return "\(version) (\(build))"
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
