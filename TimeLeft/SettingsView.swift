import Foundation
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferences: Preferences

    var body: some View {
        Form {
            Section("목표") {
                TextField("목표 이름", text: $preferences.targetName)

                Picker("카운트다운 종류", selection: $preferences.kind) {
                    ForEach(CountdownKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }

                kindControls
            }

            Section("표시") {
                Picker("메뉴 막대 표시", selection: $preferences.menuBarDisplayStyle) {
                    ForEach(MenuBarDisplayStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                Picker("표시 단위", selection: $preferences.displayUnit) {
                    ForEach(DisplayUnit.allCases) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
                Text("자동 모드는 남은 시간의 크기에 맞춰 읽기 쉬운 단위를 선택합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("진행 게이지는 다음 목표 시각에 가까워질수록 채워집니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("앱 실행") {
                LaunchAtLoginToggle()
            }

            Section("정보") {
                HStack {
                    Text("버전")
                    Spacer()
                    Text(versionString)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 460)
        .navigationTitle("Time Left 설정")
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.02"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    @ViewBuilder
    private var kindControls: some View {
        switch preferences.kind {
        case .weekdayTime:
            Picker("요일", selection: $preferences.weekday) {
                Text("일요일").tag(1)
                Text("월요일").tag(2)
                Text("화요일").tag(3)
                Text("수요일").tag(4)
                Text("목요일").tag(5)
                Text("금요일").tag(6)
                Text("토요일").tag(7)
            }
            DatePicker("시간", selection: $preferences.timeOfDay, displayedComponents: .hourAndMinute)
            Toggle("매주 반복", isOn: $preferences.repeatWeekly)
        case .todayTime:
            DatePicker("시간", selection: $preferences.timeOfDay, displayedComponents: .hourAndMinute)
            Text("오늘 시간이 지나면 완료로 표시됩니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .specificDate:
            DatePicker("목표 날짜", selection: $preferences.selectedDate, displayedComponents: [.date, .hourAndMinute])
        case .yearEnd:
            Label("현재 연도의 마지막 순간까지 계산합니다.", systemImage: "calendar")
                .foregroundStyle(.secondary)
        case .customDate:
            DatePicker("목표 날짜", selection: $preferences.selectedDate, displayedComponents: [.date, .hourAndMinute])
        }
    }
}

private struct LaunchAtLoginToggle: View {
    @State private var isEnabled = LaunchAtLoginManager.isEnabled
    @State private var errorMessage: String?

    var body: some View {
        Toggle("로그인 시 자동 실행", isOn: Binding(
            get: { isEnabled },
            set: { setLaunchAtLogin($0) }
        ))
        .onAppear { isEnabled = LaunchAtLoginManager.isEnabled }

        if LaunchAtLoginManager.requiresApproval {
            Text("시스템 설정의 로그인 항목에서 Time Left 실행을 허용하세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if let errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLoginManager.setEnabled(enabled)
            isEnabled = LaunchAtLoginManager.isEnabled
            errorMessage = nil
        } catch {
            isEnabled = LaunchAtLoginManager.isEnabled
            errorMessage = "자동 실행 설정을 변경하지 못했습니다."
        }
    }
}
