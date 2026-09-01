import SwiftUI
import AppKit

struct MenuContentView: View {
    @EnvironmentObject private var preferences: Preferences
    @EnvironmentObject private var countdown: CountdownModel
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            .padding(.vertical, 10)

            Divider()

            Text("빠른 프리셋")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 2)

            ForEach(QuickPreset.allCases) { preset in
                Button {
                    preferences.selectPreset(preset)
                } label: {
                    HStack {
                        Text(preset.title)
                        Spacer()
                        if preferences.activePreset == preset {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
            }

            Divider()

            Button {
                SettingsWindowManager.shared.show(preferences: preferences)
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
        .frame(width: 300)
    }
}
