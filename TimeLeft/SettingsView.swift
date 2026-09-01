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
                Picker("표시 단위", selection: $preferences.displayUnit) {
                    ForEach(DisplayUnit.allCases) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
                Text("자동 모드는 남은 시간의 크기에 맞춰 읽기 쉬운 단위를 선택합니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 360)
        .navigationTitle("Time Left 설정")
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
