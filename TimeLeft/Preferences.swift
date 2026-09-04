import Foundation
import Combine

enum CountdownKind: String, CaseIterable, Identifiable {
    case weekdayTime
    case todayTime
    case specificDate
    case yearEnd
    case customDate

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
    case automatic
    case seconds
    case minutes
    case hours
    case days
    case weeks
    case years

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
    case time
    case gauge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .time: return "남은 시간"
        case .gauge: return "진행 게이지"
        }
    }
}

enum QuickPreset: String, CaseIterable, Identifiable {
    case school
    case year
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .school: return "하교"
        case .year: return "올해"
        case .custom: return "사용자 지정"
        }
    }
}

final class Preferences: ObservableObject {
    private let defaults = UserDefaults.standard
    private var isLoading = true
    private var isApplyingPreset = false

    @Published var targetName: String { didSet { markAsCustom(); save() } }
    @Published var kind: CountdownKind { didSet { markAsCustom(); save() } }
    @Published var weekday: Int { didSet { markAsCustom(); save() } } // Calendar weekday: Sunday = 1
    @Published var timeOfDay: Date { didSet { markAsCustom(); save() } }
    @Published var repeatWeekly: Bool { didSet { markAsCustom(); save() } }
    @Published var selectedDate: Date { didSet { markAsCustom(); save() } }
    @Published var displayUnit: DisplayUnit { didSet { save() } }
    @Published var menuBarDisplayStyle: MenuBarDisplayStyle { didSet { save() } }
    @Published var activePreset: QuickPreset { didSet { save() } }

    init() {
        let defaultTime = Calendar.current.date(from: DateComponents(hour: 14, minute: 20)) ?? Date()
        let defaultDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        targetName = defaults.string(forKey: "targetName") ?? "하교"
        kind = CountdownKind(rawValue: defaults.string(forKey: "kind") ?? "weekdayTime") ?? .weekdayTime
        weekday = defaults.object(forKey: "weekday") as? Int ?? 6 // Friday
        timeOfDay = defaults.object(forKey: "timeOfDay") as? Date ?? defaultTime
        repeatWeekly = defaults.object(forKey: "repeatWeekly") as? Bool ?? true
        selectedDate = defaults.object(forKey: "selectedDate") as? Date ?? defaultDate
        displayUnit = DisplayUnit(rawValue: defaults.string(forKey: "displayUnit") ?? "automatic") ?? .automatic
        menuBarDisplayStyle = MenuBarDisplayStyle(rawValue: defaults.string(forKey: "menuBarDisplayStyle") ?? "time") ?? .time
        activePreset = QuickPreset(rawValue: defaults.string(forKey: "activePreset") ?? "school") ?? .school
        isLoading = false
    }

    func selectPreset(_ preset: QuickPreset) {
        isApplyingPreset = true
        defer { isApplyingPreset = false }
        activePreset = preset
        switch preset {
        case .school:
            targetName = "하교"
            kind = .weekdayTime
            weekday = 6
            timeOfDay = Calendar.current.date(from: DateComponents(hour: 14, minute: 20)) ?? timeOfDay
            repeatWeekly = true
        case .year:
            targetName = "올해"
            kind = .yearEnd
        case .custom:
            if targetName == "하교" || targetName == "올해" {
                targetName = "사용자 지정"
            }
        }
    }

    private func markAsCustom() {
        guard !isLoading, !isApplyingPreset else { return }
        activePreset = .custom
    }

    private func save() {
        guard !isLoading else { return }
        defaults.set(targetName, forKey: "targetName")
        defaults.set(kind.rawValue, forKey: "kind")
        defaults.set(weekday, forKey: "weekday")
        defaults.set(timeOfDay, forKey: "timeOfDay")
        defaults.set(repeatWeekly, forKey: "repeatWeekly")
        defaults.set(selectedDate, forKey: "selectedDate")
        defaults.set(displayUnit.rawValue, forKey: "displayUnit")
        defaults.set(menuBarDisplayStyle.rawValue, forKey: "menuBarDisplayStyle")
        defaults.set(activePreset.rawValue, forKey: "activePreset")
    }
}
