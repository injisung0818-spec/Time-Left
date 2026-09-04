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

enum DisplayUnit: String, CaseIterable, Identifiable, Codable {
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

enum MenuBarDisplayStyle: String, CaseIterable, Identifiable, Codable {
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

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "시스템 설정"
        case .light: return "라이트 모드"
        case .dark: return "다크 모드"
        }
    }
}

struct CountdownGroup: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String

    static func new() -> CountdownGroup { CountdownGroup(id: UUID(), name: "새 그룹") }
}

struct CountdownSchedule: Identifiable, Codable, Equatable {
    static let schoolID = UUID(uuidString: "D2924D34-AE4B-4595-A850-3B4729D2C4B6")!
    static let legacySchoolArrivalID = UUID(uuidString: "B5957E17-33E1-4850-BC3E-3427FA0AA5CD")!

    var id: UUID
    var name: String
    var kind: CountdownKind
    var weekday: Int
    var timeOfDay: Date
    var repeatWeekly: Bool
    var selectedDate: Date
    var isBuiltIn: Bool
    var usesSchoolCycle: Bool
    var groupID: UUID?
    var displayUnit: DisplayUnit?
    var menuBarDisplayStyle: MenuBarDisplayStyle?

    static func school() -> CountdownSchedule {
        CountdownSchedule(id: schoolID, name: "하교", kind: .weekdayTime, weekday: 6,
                          timeOfDay: Calendar.current.date(from: DateComponents(hour: 14, minute: 20)) ?? Date(), repeatWeekly: true,
                          selectedDate: Date(), isBuiltIn: true, usesSchoolCycle: true, groupID: nil, displayUnit: nil, menuBarDisplayStyle: nil)
    }

    static func new() -> CountdownSchedule {
        CountdownSchedule(id: UUID(), name: "새 일정", kind: .specificDate, weekday: 2, timeOfDay: Date(), repeatWeekly: false,
                          selectedDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(), isBuiltIn: false, usesSchoolCycle: false, groupID: nil, displayUnit: nil, menuBarDisplayStyle: nil)
    }
}

struct CountdownProfile: Identifiable, Codable, Equatable {
    static let defaultID = UUID(uuidString: "B3B475C7-3AE8-4C04-A20B-852AF68CFACD")!

    var id: UUID
    var name: String
    var groups: [CountdownGroup]
    var schedules: [CountdownSchedule]
    var isBuiltIn: Bool

    static func `default`(schedules: [CountdownSchedule]) -> CountdownProfile {
        CountdownProfile(id: defaultID, name: "기본", groups: [], schedules: schedules, isBuiltIn: true)
    }

    static func new() -> CountdownProfile {
        CountdownProfile(id: UUID(), name: "새 프로필", groups: [], schedules: [], isBuiltIn: false)
    }
}

struct ScheduleSection: Identifiable {
    let id: String
    let name: String
    let schedules: [CountdownSchedule]
}

final class Preferences: ObservableObject {
    static let appGroupID = "group.com.injisung0818.TimeLeft"
    private let defaults: UserDefaults

    @Published private(set) var profiles: [CountdownProfile]
    @Published private(set) var selectedProfileID: UUID
    @Published private(set) var selectedScheduleID: UUID?
    @Published var displayUnit: DisplayUnit { didSet { save() } }
    @Published var menuBarDisplayStyle: MenuBarDisplayStyle { didSet { save() } }
    @Published var appAppearance: AppAppearance { didSet { save() } }

    init(migrateLegacyData: Bool = true) {
        let sharedDefaults = UserDefaults(suiteName: Self.appGroupID) ?? .standard
        let legacyDefaults = UserDefaults.standard
        defaults = sharedDefaults

        var loadedProfiles: [CountdownProfile]
        if let data = sharedDefaults.data(forKey: "profiles"),
           let savedProfiles = try? JSONDecoder().decode([CountdownProfile].self, from: data), !savedProfiles.isEmpty {
            loadedProfiles = savedProfiles
        } else {
            let legacySchedules = Self.loadLegacySchedules(sharedDefaults: sharedDefaults, legacyDefaults: legacyDefaults, migrateLegacyData: migrateLegacyData)
            loadedProfiles = [CountdownProfile.default(schedules: legacySchedules)]
        }
        loadedProfiles = loadedProfiles.map(Self.normalizedProfile)
        if loadedProfiles.isEmpty { loadedProfiles = [CountdownProfile.default(schedules: [CountdownSchedule.school()])] }

        profiles = loadedProfiles
        let savedProfileID = (sharedDefaults.string(forKey: "selectedProfileID") ?? legacyDefaults.string(forKey: "selectedProfileID"))
            .flatMap(UUID.init(uuidString:))
        let activeProfileID = loadedProfiles.contains(where: { $0.id == savedProfileID }) ? savedProfileID! : loadedProfiles[0].id
        selectedProfileID = activeProfileID

        let savedScheduleID = (sharedDefaults.string(forKey: "selectedScheduleID") ?? legacyDefaults.string(forKey: "selectedScheduleID"))
            .flatMap(UUID.init(uuidString:))
        let currentSchedules = loadedProfiles.first(where: { $0.id == activeProfileID })?.schedules ?? []
        selectedScheduleID = currentSchedules.contains(where: { $0.id == savedScheduleID }) ? savedScheduleID : currentSchedules.first?.id

        displayUnit = DisplayUnit(rawValue: sharedDefaults.string(forKey: "displayUnit") ?? legacyDefaults.string(forKey: "displayUnit") ?? "automatic") ?? .automatic
        menuBarDisplayStyle = MenuBarDisplayStyle(rawValue: sharedDefaults.string(forKey: "menuBarDisplayStyle") ?? legacyDefaults.string(forKey: "menuBarDisplayStyle") ?? "compact") ?? .compact
        appAppearance = AppAppearance(rawValue: sharedDefaults.string(forKey: "appAppearance") ?? legacyDefaults.string(forKey: "appAppearance") ?? "system") ?? .system
        if migrateLegacyData { save(reloadWidgets: false) }
    }

    var selectedProfile: CountdownProfile { profiles.first(where: { $0.id == selectedProfileID }) ?? profiles[0] }
    var schedules: [CountdownSchedule] { selectedProfile.schedules }
    var groups: [CountdownGroup] { selectedProfile.groups }
    var selectedSchedule: CountdownSchedule? {
        guard let selectedScheduleID else { return nil }
        return schedules.first(where: { $0.id == selectedScheduleID })
    }

    var selectedMenuBarDisplayStyle: MenuBarDisplayStyle {
        selectedSchedule?.menuBarDisplayStyle ?? menuBarDisplayStyle
    }

    func displayUnit(for schedule: CountdownSchedule? = nil) -> DisplayUnit {
        (schedule ?? selectedSchedule)?.displayUnit ?? displayUnit
    }

    func scheduleSections(includeEmptyGroups: Bool = false) -> [ScheduleSection] {
        let knownGroupIDs = Set(groups.map(\.id))
        var sections = groups.compactMap { group -> ScheduleSection? in
            let items = schedules.filter { $0.groupID == group.id }
            guard includeEmptyGroups || !items.isEmpty else { return nil }
            return ScheduleSection(id: group.id.uuidString, name: group.name, schedules: items)
        }
        let other = schedules.filter { $0.groupID == nil || !knownGroupIDs.contains($0.groupID!) }
        if !other.isEmpty { sections.append(ScheduleSection(id: "other", name: "기타", schedules: other)) }
        return sections
    }

    func selectProfile(_ profile: CountdownProfile) {
        selectedProfileID = profile.id
        selectedScheduleID = profile.schedules.first?.id
        save()
    }

    func addProfile(_ profile: CountdownProfile) {
        profiles.append(profile)
        selectProfile(profile)
    }

    func updateProfile(_ profile: CountdownProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        save()
    }

    func deleteProfile(_ profile: CountdownProfile) {
        guard !profile.isBuiltIn, profiles.count > 1 else { return }
        profiles.removeAll { $0.id == profile.id }
        if selectedProfileID == profile.id {
            selectedProfileID = profiles[0].id
            selectedScheduleID = profiles[0].schedules.first?.id
        }
        save()
    }

    func addGroup(_ group: CountdownGroup) {
        mutateSelectedProfile { $0.groups.append(group) }
    }

    func updateGroup(_ group: CountdownGroup) {
        mutateSelectedProfile { profile in
            guard let index = profile.groups.firstIndex(where: { $0.id == group.id }) else { return }
            profile.groups[index] = group
        }
    }

    func deleteGroup(_ group: CountdownGroup) {
        mutateSelectedProfile { profile in
            profile.groups.removeAll { $0.id == group.id }
            for index in profile.schedules.indices where profile.schedules[index].groupID == group.id {
                profile.schedules[index].groupID = nil
            }
        }
    }

    func selectSchedule(_ schedule: CountdownSchedule) { selectedScheduleID = schedule.id; save() }
    func addSchedule(_ schedule: CountdownSchedule) {
        mutateSelectedProfile { profile in
            var newSchedule = schedule
            if let groupID = newSchedule.groupID, !profile.groups.contains(where: { $0.id == groupID }) { newSchedule.groupID = nil }
            profile.schedules.append(newSchedule)
            selectedScheduleID = newSchedule.id
        }
    }

    func updateSchedule(_ schedule: CountdownSchedule) {
        mutateSelectedProfile { profile in
            guard let index = profile.schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
            var updatedSchedule = schedule
            if let groupID = updatedSchedule.groupID, !profile.groups.contains(where: { $0.id == groupID }) { updatedSchedule.groupID = nil }
            profile.schedules[index] = updatedSchedule
        }
    }

    func deleteSchedule(_ schedule: CountdownSchedule) {
        guard !schedule.isBuiltIn else { return }
        mutateSelectedProfile { profile in
            profile.schedules.removeAll { $0.id == schedule.id }
            if selectedScheduleID == schedule.id { selectedScheduleID = profile.schedules.first?.id }
        }
    }

    private func mutateSelectedProfile(_ mutation: (inout CountdownProfile) -> Void) {
        guard let index = profiles.firstIndex(where: { $0.id == selectedProfileID }) else { return }
        mutation(&profiles[index])
        save()
    }

    private static func loadLegacySchedules(sharedDefaults: UserDefaults, legacyDefaults: UserDefaults, migrateLegacyData: Bool) -> [CountdownSchedule] {
        var values: [CountdownSchedule]
        if let data = sharedDefaults.data(forKey: "schedules"),
           let savedSchedules = try? JSONDecoder().decode([CountdownSchedule].self, from: data), !savedSchedules.isEmpty {
            values = savedSchedules
        } else if migrateLegacyData {
            values = migratedSchedules(defaults: legacyDefaults)
        } else {
            values = [CountdownSchedule.school()]
        }
        values.removeAll { $0.id == CountdownSchedule.legacySchoolArrivalID }
        if let schoolIndex = values.firstIndex(where: { $0.id == CountdownSchedule.schoolID }) {
            values[schoolIndex] = CountdownSchedule.school()
        } else {
            values.insert(CountdownSchedule.school(), at: 0)
        }
        return values
    }

    private static func normalizedProfile(_ profile: CountdownProfile) -> CountdownProfile {
        var profile = profile
        profile.name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "프로필" : profile.name
        profile.groups = profile.groups.map { group in
            var group = group
            group.name = group.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "새 그룹" : group.name
            return group
        }
        return profile
    }

    private static func migratedSchedules(defaults: UserDefaults) -> [CountdownSchedule] {
        var values = [CountdownSchedule.school()]
        let legacyName = defaults.string(forKey: "targetName") ?? "하교"
        let legacyKind = CountdownKind(rawValue: defaults.string(forKey: "kind") ?? "weekdayTime") ?? .weekdayTime
        if legacyName != "하교" || legacyKind != .weekdayTime {
            values.append(CountdownSchedule(id: UUID(), name: legacyName, kind: legacyKind,
                                            weekday: defaults.object(forKey: "weekday") as? Int ?? 6,
                                            timeOfDay: defaults.object(forKey: "timeOfDay") as? Date ?? Date(),
                                            repeatWeekly: defaults.object(forKey: "repeatWeekly") as? Bool ?? true,
                                            selectedDate: defaults.object(forKey: "selectedDate") as? Date ?? Date(),
                                            isBuiltIn: false, usesSchoolCycle: false, groupID: nil, displayUnit: nil, menuBarDisplayStyle: nil))
        }
        return values
    }

    private func save(reloadWidgets: Bool = true) {
        defaults.set(try? JSONEncoder().encode(profiles), forKey: "profiles")
        defaults.set(selectedProfileID.uuidString, forKey: "selectedProfileID")
        defaults.set(selectedScheduleID?.uuidString, forKey: "selectedScheduleID")
        defaults.set(displayUnit.rawValue, forKey: "displayUnit")
        defaults.set(menuBarDisplayStyle.rawValue, forKey: "menuBarDisplayStyle")
        defaults.set(appAppearance.rawValue, forKey: "appAppearance")
        if reloadWidgets { WidgetCenter.shared.reloadAllTimelines() }
    }
}
