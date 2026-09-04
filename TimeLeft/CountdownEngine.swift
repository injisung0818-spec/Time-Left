import Foundation
import Combine

struct CountdownSnapshot {
    let targetDate: Date?
    let remaining: TimeInterval
    let progress: Double
    let isComplete: Bool
    let menuBarText: String
    let detailText: String
}

enum CountdownEngine {
    static func snapshot(preferences: Preferences, now: Date = Date(), calendar: Calendar = .current) -> CountdownSnapshot {
        let schedule = preferences.selectedSchedule
        let target = targetDate(schedule: schedule, now: now, calendar: calendar)
        let remaining = max(0, (target ?? now).timeIntervalSince(now))
        let progress = progressValue(schedule: schedule, target: target, now: now, calendar: calendar)
        let isComplete = target.map { now >= $0 } ?? false
        let name = displayName(schedule: schedule, target: target, calendar: calendar)
        let prefix = name

        if isComplete {
            return CountdownSnapshot(
                targetDate: target,
                remaining: 0,
                progress: 1,
                isComplete: true,
                menuBarText: "완료",
                detailText: "\(prefix) 목표가 완료되었습니다. 설정에서 새 목표를 지정할 수 있습니다."
            )
        }

        let duration = formatDuration(remaining, unit: preferences.displayUnit, calendar: calendar)
        return CountdownSnapshot(
            targetDate: target,
            remaining: remaining,
            progress: progress,
            isComplete: false,
            menuBarText: duration,
            detailText: "\(prefix)까지 \(duration) 남았습니다."
        )
    }

    static func targetDate(schedule: CountdownSchedule, now: Date, calendar: Calendar) -> Date? {
        switch schedule.kind {
        case .weekdayTime:
            if schedule.usesSchoolCycle, schedule.repeatWeekly {
                return schoolTarget(now: now, calendar: calendar)
            }
            return weekdayTarget(schedule: schedule, now: now, calendar: calendar)
        case .todayTime:
            return date(on: now, time: schedule.timeOfDay, calendar: calendar)
        case .specificDate, .customDate:
            return schedule.selectedDate
        case .yearEnd:
            let year = calendar.component(.year, from: now)
            return calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        }
    }

    static func formatDuration(_ duration: TimeInterval, unit: DisplayUnit, calendar: Calendar = .current) -> String {
        let seconds = max(0, duration)
        switch unit {
        case .seconds:
            return "\(Int(seconds.rounded(.up)))s"
        case .minutes:
            return "\(formatDecimal(seconds / 60))m"
        case .hours:
            return "\(formatDecimal(seconds / 3_600))h"
        case .days:
            return "\(formatDecimal(seconds / 86_400))d"
        case .weeks:
            return "\(formatDecimal(seconds / 604_800))w"
        case .years:
            return "\(formatDecimal(seconds / 31_536_000))y"
        case .automatic:
            return automaticDuration(seconds)
        }
    }

    static func formattedTargetDate(_ date: Date?, calendar: Calendar = .current) -> String {
        guard let date else { return "목표 시간이 없습니다" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func progressValue(schedule: CountdownSchedule, target: Date?, now: Date, calendar: Calendar) -> Double {
        guard let target else { return 0 }
        let start: Date?

        switch schedule.kind {
        case .weekdayTime where schedule.repeatWeekly:
            if schedule.usesSchoolCycle {
                start = schoolCycleStart(target: target, calendar: calendar)
            } else {
                start = calendar.date(byAdding: .day, value: -7, to: target)
            }
        case .yearEnd:
            let year = calendar.component(.year, from: target) - 1
            start = calendar.date(from: DateComponents(year: year, month: 1, day: 1))
        default:
            // One-time dates have no previous cycle. Their bar begins when the app starts tracking them.
            start = nil
        }

        guard let start else { return 0 }
        let duration = target.timeIntervalSince(start)
        guard duration > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(start) / duration))
    }

    private static func schoolCycleStart(target: Date, calendar: Calendar) -> Date? {
        let weekday = calendar.component(.weekday, from: target)
        let hour = calendar.component(.hour, from: target)

        // Sunday 21:00 follows that Friday's 14:20. Friday 14:20 follows the prior Sunday 21:00.
        if weekday == 1 && hour == 21 {
            return calendar.date(byAdding: .day, value: -2, to: target)
        }
        return calendar.date(byAdding: .day, value: -5, to: target)
    }

    private static func displayName(schedule: CountdownSchedule, target: Date?, calendar: Calendar) -> String {
        let configuredName = schedule.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "카운트다운" : schedule.name
        guard schedule.usesSchoolCycle,
              schedule.kind == .weekdayTime,
              schedule.repeatWeekly,
              let target,
              calendar.component(.weekday, from: target) == 1,
              calendar.component(.hour, from: target) == 21,
              calendar.component(.minute, from: target) == 0
        else { return configuredName }

        return "등교"
    }

    private static func weekdayTarget(schedule: CountdownSchedule, now: Date, calendar: Calendar) -> Date? {
        let time = calendar.dateComponents([.hour, .minute], from: schedule.timeOfDay)
        var current = calendar.dateComponents([.year, .month, .day, .weekday], from: now)
        current.hour = time.hour
        current.minute = time.minute
        current.second = 0
        guard let currentWeekday = current.weekday,
              let candidate = calendar.date(from: current) else { return nil }

        let dayOffset = (schedule.weekday - currentWeekday + 7) % 7
        var next = calendar.date(byAdding: .day, value: dayOffset, to: candidate) ?? candidate
        if schedule.repeatWeekly, next <= now {
            next = calendar.date(byAdding: .day, value: 7, to: next) ?? next
        }
        return next
    }

    /// The school preset has a two-step weekly schedule:
    /// Friday 14:20 → Sunday 21:00 → next Friday 14:20.
    private static func schoolTarget(now: Date, calendar: Calendar) -> Date? {
        let today = calendar.dateComponents([.year, .month, .day, .weekday], from: now)
        guard let currentWeekday = today.weekday else { return nil }

        var fridayComponents = today
        fridayComponents.hour = 14
        fridayComponents.minute = 20
        fridayComponents.second = 0
        guard let todayAtSchoolTime = calendar.date(from: fridayComponents) else { return nil }

        // Find this week's Friday, including a Friday that has already passed.
        let daysSinceFriday = (currentWeekday - 6 + 7) % 7
        guard let thisFriday = calendar.date(byAdding: .day, value: -daysSinceFriday, to: todayAtSchoolTime),
              let thisSunday = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 2, to: thisFriday) ?? thisFriday)
        else { return nil }

        if now < thisFriday {
            return thisFriday
        }
        if now < thisSunday {
            return thisSunday
        }
        return calendar.date(byAdding: .day, value: 7, to: thisFriday)
    }

    private static func date(on day: Date, time: Date, calendar: Calendar) -> Date? {
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var components = dayComponents
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.second = 0
        return calendar.date(from: components)
    }

    private static func automaticDuration(_ seconds: TimeInterval) -> String {
        let wholeSeconds = Int(seconds.rounded(.down))
        if wholeSeconds < 60 { return "\(max(0, Int(seconds.rounded(.up))))s" }

        let minutes = wholeSeconds / 60
        if minutes < 60 { return "\(minutes)m" }

        let hours = minutes / 60
        if hours < 24 {
            let remainder = minutes % 60
            return remainder == 0 ? "\(hours)h" : "\(hours)h \(remainder)m"
        }

        let days = hours / 24
        if days < 7 {
            let remainder = hours % 24
            return remainder == 0 ? "\(days)d" : "\(days)d \(remainder)h"
        }

        let weeks = days / 7
        let remainder = days % 7
        return remainder == 0 ? "\(weeks)w" : "\(weeks)w \(remainder)d"
    }

    private static func formatDecimal(_ value: TimeInterval) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded.rounded() == rounded { return String(Int(rounded)) }
        return String(format: "%.2f", rounded).replacingOccurrences(of: ".00", with: "")
    }

}

final class CountdownModel: ObservableObject {
    @Published private(set) var snapshot: CountdownSnapshot
    private var timer: Timer?
    private var preferencesCancellable: AnyCancellable?
    private let preferences: Preferences

    init(preferences: Preferences) {
        self.preferences = preferences
        snapshot = CountdownEngine.snapshot(preferences: preferences)
        preferencesCancellable = preferences.objectWillChange.sink { [weak self] _ in
            // @Published emits before the wrapped value is set; refresh on the next run-loop turn.
            DispatchQueue.main.async { [weak self] in
                self?.refresh()
            }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    deinit {
        timer?.invalidate()
        preferencesCancellable?.cancel()
    }

    func refresh() {
        snapshot = CountdownEngine.snapshot(preferences: preferences)
    }
}
