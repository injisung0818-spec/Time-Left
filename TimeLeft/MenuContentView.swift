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
}
