import AppKit
import SwiftUI
import WidgetKit

struct TimeLeftWidgetEntry: TimelineEntry {
    let date: Date
    let schedules: [WidgetSchedule]
}

struct WidgetSchedule: Identifiable {
    let id: UUID
    let name: String
    let remaining: String
    let isSelected: Bool
}

struct TimeLeftWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimeLeftWidgetEntry {
        TimeLeftWidgetEntry(date: Date(), schedules: [
            WidgetSchedule(id: UUID(), name: "하교", remaining: "2h 10m", isSelected: true),
            WidgetSchedule(id: UUID(), name: "시험", remaining: "3d 4h", isSelected: false)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeLeftWidgetEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimeLeftWidgetEntry>) -> Void) {
        let now = Date()
        let entries = (0..<60).compactMap { minute -> TimeLeftWidgetEntry? in
            guard let date = Calendar.current.date(byAdding: .minute, value: minute, to: now) else { return nil }
            return makeEntry(at: date)
        }
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 60, to: now) ?? now.addingTimeInterval(3_600)
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }

    private func makeEntry(at date: Date) -> TimeLeftWidgetEntry {
        let preferences = Preferences(migrateLegacyData: false)
        let rows = preferences.schedules.map { schedule -> (WidgetSchedule, Date) in
            let target = CountdownEngine.targetDate(schedule: schedule, now: date, calendar: .current)
            let remaining = max(0, (target ?? date).timeIntervalSince(date))
            let sortDate = target.map { $0 > date ? $0 : .distantFuture } ?? .distantFuture
            return (
                WidgetSchedule(
                    id: schedule.id,
                    name: schedule.name,
                    remaining: CountdownEngine.widgetDuration(remaining),
                    isSelected: schedule.id == preferences.selectedScheduleID
                ),
                sortDate
            )
        }
        .sorted { $0.1 < $1.1 }
        .prefix(5)
        .map(\.0)

        return TimeLeftWidgetEntry(date: date, schedules: rows)
    }
}

struct TimeLeftWidgetView: View {
    let entry: TimeLeftWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Time Left")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.secondary)

            if entry.schedules.isEmpty {
                Spacer()
                Text("저장된 일정이 없습니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(entry.schedules) { schedule in
                    HStack(spacing: 4) {
                        Text(schedule.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .layoutPriority(1)
                        Text("·")
                        Text(schedule.remaining)
                            .monospacedDigit()
                            .fixedSize()
                    }
                    .font(.system(size: 14))
                    .fontWeight(schedule.isSelected ? .bold : .regular)
                    .foregroundStyle(schedule.isSelected ? Color.accentColor : Color.primary)
                }
                Spacer(minLength: 0)
            }
        }
        .padding()
        .widgetURL(URL(string: "timeleft://open"))
        .timeLeftWidgetBackground()
    }
}

private extension View {
    @ViewBuilder
    func timeLeftWidgetBackground() -> some View {
        if #available(macOS 14.0, *) {
            containerBackground(for: .widget) {
                Color(nsColor: .windowBackgroundColor)
            }
        } else {
            background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

@main
struct TimeLeftWidget: Widget {
    let kind = "TimeLeftWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimeLeftWidgetProvider()) { entry in
            TimeLeftWidgetView(entry: entry)
        }
        .configurationDisplayName("Time Left")
        .description("저장된 카운트다운 일정을 가까운 순서로 확인합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
