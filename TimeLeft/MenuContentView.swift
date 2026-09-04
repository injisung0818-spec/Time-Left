import SwiftUI
import AppKit

struct MenuContentView: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var updateChecker: GitHubReleaseChecker

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

            Text("기타")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 7)
                .padding(.bottom, 2)

            if otherSchedules.isEmpty {
                Text("전환할 일정이 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
            } else {
                ForEach(otherSchedules) { schedule in
                    Button {
                        preferences.selectSchedule(schedule)
                    } label: {
                        HStack {
                            Text(currentName(for: schedule))
                                .fontWeight(preferences.selectedScheduleID == schedule.id ? .semibold : .regular)
                            Spacer()
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
            }

            Divider()

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

    private var otherSchedules: [CountdownSchedule] {
        preferences.scheduleSections().first(where: { $0.id == "other" })?.schedules ?? []
    }

    private func currentName(for schedule: CountdownSchedule) -> String {
        let target = CountdownEngine.targetDate(schedule: schedule, now: Date(), calendar: .current)
        return CountdownEngine.displayName(schedule: schedule, target: target, calendar: .current)
    }
}
