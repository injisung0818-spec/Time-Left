import Foundation
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var updateChecker: GitHubReleaseChecker
    @State private var scheduleToEdit: CountdownSchedule?
    @State private var isAdding = false

    var body: some View {
        Form {
            Section {
                ForEach(preferences.schedules) { schedule in
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
            } header: {
                HStack {
                    Text("카운트다운 일정")
                    Spacer()
                    Button { isAdding = true } label: { Image(systemName: "plus") }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("새 일정 추가")
                }
            } footer: {
                Text("하교와 등교는 기본 일정으로 유지됩니다. 사용자 지정 일정은 수정하거나 삭제할 수 있습니다.")
            }

            Section("표시") {
                Picker("메뉴 막대 표시", selection: $preferences.menuBarDisplayStyle) {
                    ForEach(MenuBarDisplayStyle.allCases) { style in Text(style.title).tag(style) }
                }
                if preferences.menuBarDisplayStyle == .compact {
                    Picker("표시 단위", selection: $preferences.displayUnit) {
                        ForEach(DisplayUnit.allCases) { unit in Text(unit.title).tag(unit) }
                    }
                }
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
        .frame(width: 480, height: 540)
        .navigationTitle("Time Left 설정")
        .onAppear { updateChecker.checkForLatestRelease() }
        .sheet(isPresented: $isAdding) {
            ScheduleEditorSheet(schedule: .new()) { preferences.addSchedule($0) }
        }
        .sheet(item: $scheduleToEdit) { schedule in
            ScheduleEditorSheet(schedule: schedule) { preferences.updateSchedule($0) }
        }
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.2"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "8"
        return "\(version) (\(build))"
    }
}

private struct ScheduleEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CountdownSchedule
    let onSave: (CountdownSchedule) -> Void

    init(schedule: CountdownSchedule, onSave: @escaping (CountdownSchedule) -> Void) {
        _draft = State(initialValue: schedule)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("일정 이름", text: $draft.name)
                Picker("카운트다운 종류", selection: $draft.kind) {
                    ForEach(CountdownKind.allCases) { kind in Text(kind.title).tag(kind) }
                }
                scheduleControls
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
        .frame(width: 420, height: 340)
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
