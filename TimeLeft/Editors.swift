import SwiftUI

struct ScheduleEditorSheet: View {
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

struct ProfileEditorSheet: View {
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

struct GroupEditorSheet: View {
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
