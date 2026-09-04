import Foundation
import Combine
import WidgetKit

enum CountdownKind: String, CaseIterable, Identifiable, Codable {
    case weekdayTime, todayTime, specificDate, yearEnd, customDate
    var id: String { rawValue }
    var title: String {
        switch self {
        case .weekdayTime: return "특정 요일 / 시간"
        case .todayTime: return "오늘의 특정 시간"
        case .specificDate: return "특정 날짜와 시간"
        case .yearEnd: return "올해가 끝날 때까지"
        case .customDate: return "사용자 지정 날짜"
        }
    }
}

enum DisplayUnit: String, CaseIterable, Identifiable {
    case automatic, seconds, minutes, hours, days, weeks, years
    var id: String { rawValue }
    var title: String {
        switch self {
        case .automatic: return "자동"
        case .seconds: return "s"
        case .minutes: return "m"
        case .hours: return "h"
        case .days: return "d"
        case .weeks: return "w"
        case .years: return "y"
        }
    }
}

enum MenuBarDisplayStyle: String, CaseIterable, Identifiable {
    case compact, digital, icon
    var id: String { rawValue }
    var title: String {
        switch self {
        case .compact: return "기본"
        case .digital: return "00:00:00 형식"
        case .icon: return "아이콘만"
        }
    }
}

struct CountdownSchedule: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var kind: CountdownKind
    var weekday: Int
    var timeOfDay: Date
    var repeatWeekly: Bool
    var selectedDate: Date
    var isBuiltIn: Bool
    var usesSchoolCycle: Bool

    static func school() -> CountdownSchedule {
        CountdownSchedule(id: UUID(uuidString: "D2924D34-AE4B-4595-A850-3B4729D2C4B6")!, name: "하교", kind: .weekdayTime, weekday: 6,
                          timeOfDay: Calendar.current.date(from: DateComponents(hour: 14, minute: 20)) ?? Date(), repeatWeekly: true,
                          selectedDate: Date(), isBuiltIn: true, usesSchoolCycle: true)
    }

    static func schoolArrival() -> CountdownSchedule {
        CountdownSchedule(id: UUID(uuidString: "B5957E17-33E1-4850-BC3E-3427FA0AA5CD")!, name: "등교", kind: .weekdayTime, weekday: 1,
                          timeOfDay: Calendar.current.date(from: DateComponents(hour: 21, minute: 0)) ?? Date(), repeatWeekly: true,
                          selectedDate: Date(), isBuiltIn: true, usesSchoolCycle: false)
    }

    static func new() -> CountdownSchedule {
        CountdownSchedule(id: UUID(), name: "새 일정", kind: .specificDate, weekday: 2, timeOfDay: Date(), repeatWeekly: false,
                          selectedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(), isBuiltIn: false, usesSchoolCycle: false)
    }
}

final class Preferences: ObservableObject {
    static let appGroupID = "group.com.injisung0818.TimeLeft"
    private let defaults: UserDefaults

    @Published private(set) var schedules: [CountdownSchedule]
    @Published private(set) var selectedScheduleID: UUID
    @Published var displayUnit: DisplayUnit { didSet { save() } }
    @Published var menuBarDisplayStyle: MenuBarDisplayStyle { didSet { save() } }

    init(migrateLegacyData: Bool = true) {
        let sharedDefaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        let legacyDefaults = UserDefaults.standard
        defaults = sharedDefaults
        let loadedSchedules: [CountdownSchedule]
        if let data = sharedDefaults.data(forKey: "schedules"),
           let savedSchedules = try? JSONDecoder().decode([CountdownSchedule].self, from: data), !savedSchedules.isEmpty {
            loadedSchedules = savedSchedules
        } else if migrateLegacyData {
            loadedSchedules = Self.migratedSchedules(defaults: legacyDefaults)
        } else {
            loadedSchedules = [CountdownSchedule.school(), CountdownSchedule.schoolArrival()]
        }
        schedules = loadedSchedules
        let savedID = (sharedDefaults.string(forKey: "selectedScheduleID") ?? legacyDefaults.string(forKey: "selectedScheduleID"))
            .flatMap(UUID.init(uuidString:))
        selectedScheduleID = loadedSchedules.contains(where: { $0.id == savedID }) ? savedID! : loadedSchedules[0].id
        displayUnit = DisplayUnit(rawValue: sharedDefaults.string(forKey: "displayUnit") ?? legacyDefaults.string(forKey: "displayUnit") ?? "automatic") ?? .automatic
        // Older saved values (time/gauge) migrate to the compact text display.
        menuBarDisplayStyle = MenuBarDisplayStyle(rawValue: sharedDefaults.string(forKey: "menuBarDisplayStyle") ?? legacyDefaults.string(forKey: "menuBarDisplayStyle") ?? "compact") ?? .compact
        if migrateLegacyData {
            save(reloadWidgets: false)
        }
    }

    var selectedSchedule: CountdownSchedule { schedules.first(where: { $0.id == selectedScheduleID }) ?? schedules[0] }

    func selectSchedule(_ schedule: CountdownSchedule) { selectedScheduleID = schedule.id; save() }
    func addSchedule(_ schedule: CountdownSchedule) { schedules.append(schedule); selectedScheduleID = schedule.id; save() }
    func updateSchedule(_ schedule: CountdownSchedule) {
        guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        schedules[index] = schedule; save()
    }
    func deleteSchedule(_ schedule: CountdownSchedule) {
        guard !schedule.isBuiltIn else { return }
        schedules.removeAll { $0.id == schedule.id }
        if selectedScheduleID == schedule.id { selectedScheduleID = schedules[0].id }
        save()
    }

    private static func migratedSchedules(defaults: UserDefaults) -> [CountdownSchedule] {
        var values = [CountdownSchedule.school(), CountdownSchedule.schoolArrival()]
        let legacyName = defaults.string(forKey: "targetName") ?? "하교"
        let legacyKind = CountdownKind(rawValue: defaults.string(forKey: "kind") ?? "weekdayTime") ?? .weekdayTime
        if legacyName != "하교" || legacyKind != .weekdayTime {
            values.append(CountdownSchedule(id: UUID(), name: legacyName, kind: legacyKind,
                                            weekday: defaults.object(forKey: "weekday") as? Int ?? 6,
                                            timeOfDay: defaults.object(forKey: "timeOfDay") as? Date ?? Date(),
                                            repeatWeekly: defaults.object(forKey: "repeatWeekly") as? Bool ?? true,
                                            selectedDate: defaults.object(forKey: "selectedDate") as? Date ?? Date(),
                                            isBuiltIn: false, usesSchoolCycle: false))
        }
        return values
    }

    private func save(reloadWidgets: Bool = true) {
        defaults.set(try? JSONEncoder().encode(schedules), forKey: "schedules")
        defaults.set(selectedScheduleID.uuidString, forKey: "selectedScheduleID")
        defaults.set(displayUnit.rawValue, forKey: "displayUnit")
        defaults.set(menuBarDisplayStyle.rawValue, forKey: "menuBarDisplayStyle")
        if reloadWidgets {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
