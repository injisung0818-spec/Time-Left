import AppKit
import SwiftUI

struct MenuContentView: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var countdown: CountdownModel
    @EnvironmentObject private var updateChecker: GitHubReleaseChecker

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(countdown.snapshot.detailText)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                if let targetDate = countdown.snapshot.targetDate {
                    Text(CountdownEngine.formattedTargetDate(targetDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)

            Divider()

            Menu {
                ForEach(preferences.profiles) { profile in
                    Button {
                        preferences.selectProfile(profile)
                    } label: {
                        if preferences.selectedProfileID == profile.id {
                            Label(profile.name, systemImage: "checkmark")
                        } else {
                            Text(profile.name)
                        }
                    }
                }
            } label: {
                Label("프로필 · \(preferences.selectedProfile.name)", systemImage: "person.crop.circle")
            }
            .menuStyle(.borderlessButton)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)

            Divider()

            if preferences.scheduleSections().isEmpty {
                Text("이 프로필에 저장된 일정이 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ForEach(preferences.scheduleSections()) { section in
                    Text(section.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 7)
                        .padding(.bottom, 2)

                    ForEach(Array(section.schedules.prefix(8))) { schedule in
                        Button {
                            preferences.selectSchedule(schedule)
                        } label: {
                            HStack {
                                Text(currentName(for: schedule))
                                    .fontWeight(preferences.selectedScheduleID == schedule.id ? .semibold : .regular)
                                Spacer()
                                Text(remainingText(for: schedule))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                                if preferences.selectedScheduleID == schedule.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .buttonStyle(.borderless)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    }

                    if section.schedules.count > 8 {
                        Text("추가 \(section.schedules.count - 8)개는 설정에서 확인할 수 있습니다.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 4)
                    }
                }
            }

            Divider()

            Button { openNewSchedule() } label: {
                Label("새 일정", systemImage: "plus")
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)

            Button {
                SettingsWindowManager.shared.show(preferences: preferences, updateChecker: updateChecker)
            } label: {
                Label("설정", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)

            Button("종료") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 310)
    }

    private func openNewSchedule() {
        SettingsWindowManager.shared.show(preferences: preferences, updateChecker: updateChecker)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .timeLeftAddSchedule, object: nil)
        }
    }

    private func currentName(for schedule: CountdownSchedule) -> String {
        let target = CountdownEngine.targetDate(schedule: schedule, now: Date(), calendar: .current)
        return CountdownEngine.displayName(schedule: schedule, target: target, calendar: .current)
    }

    private func remainingText(for schedule: CountdownSchedule) -> String {
        let now = Date()
        guard let target = CountdownEngine.targetDate(schedule: schedule, now: now, calendar: .current), target > now else {
            return "완료"
        }
        return CountdownEngine.widgetDuration(target.timeIntervalSince(now))
    }
}
