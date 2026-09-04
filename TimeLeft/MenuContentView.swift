import SwiftUI
import AppKit

struct MenuContentView: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var countdown: CountdownModel
    @EnvironmentObject private var updateChecker: GitHubReleaseChecker

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("프로필")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
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
                    HStack(spacing: 4) {
                        Text(preferences.selectedProfile.name)
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                    }
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.horizontal, 12)
            .padding(.top, 9)
            .padding(.bottom, 6)

            VStack(alignment: .leading, spacing: 5) {
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
            .padding(.vertical, 8)

            Divider()

            HStack {
                Text("빠르게 전환")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button { openNewSchedule() } label: { Image(systemName: "plus") }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("새 일정 추가")
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 2)

            if preferences.schedules.isEmpty {
                Text("이 프로필에 저장된 일정이 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                ForEach(preferences.scheduleSections()) { section in
                    Text(section.name)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 6)
                        .padding(.bottom, 1)

                    ForEach(section.schedules) { schedule in
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
            }

            Divider()

            Menu {
                ForEach(AppAppearance.allCases) { appearance in
                    Button {
                        preferences.appAppearance = appearance
                        AppearanceManager.shared.apply(appearance)
                    } label: {
                        if preferences.appAppearance == appearance {
                            Label(appearance.title, systemImage: "checkmark")
                        } else {
                            Text(appearance.title)
                        }
                    }
                }
            } label: {
                Label("앱 모드", systemImage: "circle.lefthalf.filled")
            }
            .menuStyle(.borderlessButton)
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
}
