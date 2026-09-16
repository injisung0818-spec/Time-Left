# Time Left

[한국어](README.md) | English

<img src="TimeLeft/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" width="96" alt="Time Left app icon">

Time Left is a macOS countdown utility that shows the remaining time to your selected event in the menu bar. Organize different contexts—such as school, work, and personal life—into profiles and groups, then quickly view the next event from the menu bar or a widget.

Instructions for building from source are below. Prebuilt apps, when available, are published through [GitHub Releases](https://github.com/injisung0818-spec/Time-Left/releases).

## Download

Get the latest build from [GitHub Releases](https://github.com/injisung0818-spec/Time-Left/releases/latest).

1. Download `Time-Left-<version>.app.zip`.
2. Unzip it and move `Time Left.app` to **Applications**.
3. Launch the app, then select its menu bar icon to view events or open Settings.

Release notes should state each build's code-signing and notarization status. Unsigned or non-notarized builds may require macOS approval before launch.

## Features

- An `LSUIElement` macOS app that lives in the menu bar.
- Separates schedules into profiles for school, work, personal life, and more.
- Organizes each profile with groups such as classes, exams, and breaks; ungrouped schedules appear under `Other`.
- Counts down to a weekday and time (optionally repeating weekly), a time today, a specific date and time, the end of the year, or a custom date.
- Shows remaining time in a compact format, as `00:00:00`, or as an icon only; display units can be set per schedule.
- Lets you browse and switch schedules by group in the menu bar popover.
- Shows up to five upcoming schedules in WidgetKit desktop and Notification Center widgets, highlighting the selected schedule.
- Uses `SMAppService` to launch at login only when enabled in Settings.
- Supports `timeleft://open` and `timeleft://schedule/<schedule UUID>` deep links.
- Checks GitHub Releases for a newer version when the app starts and when Settings opens.

## Built-in school preset

The first launch includes `하교` (leave school). Rather than a normal weekly recurrence, the preset follows this school cycle:

| Current time | Next target |
| --- | --- |
| Before Friday 14:20 | `하교` at Friday 14:20 that week |
| Friday 14:20 through before Sunday 21:00 | `등교` (go to school) at Sunday 21:00 |
| From Sunday 21:00 onward | `하교` at Friday 14:20 the following week |

This behavior only applies to the built-in preset. Custom weekly schedules repeat at their configured weekday and time.

## Compatibility

| Item | Support |
| --- | --- |
| Deployment target | macOS 13.0 and later |
| App UI | SwiftUI |
| Widgets | WidgetKit desktop and Notification Center widgets |

The deployment target is defined in [`TimeLeft/Info.plist`](TimeLeft/Info.plist) and the widget's `Info.plist`. It is a build target, not a guarantee that every macOS release has been individually validated.

## Privacy

Schedules, profiles, and display preferences are stored locally in the App Group `UserDefaults` shared by the app and widget. Schedule data is not sent to an external service.

The app contacts the GitHub Releases API only to check for a new version. Widgets reload only when a schedule or profile change affects their content.

## Building from source

Time Left is an Xcode project using SwiftUI and WidgetKit. You need an Xcode version capable of building for macOS 13 or later.

1. Clone and enter the repository.

   ```bash
   git clone https://github.com/injisung0818-spec/Time-Left.git
   cd Time-Left
   ```

2. Open `TimeLeft.xcodeproj` in Xcode.
3. Select the `Time Left` scheme, then build and run.

You can also build from the command line:

```bash
xcodebuild -project TimeLeft.xcodeproj -scheme 'Time Left' build
```

## Tests

Countdown engine tests cover the school cycle, weekly recurrence, expired one-time schedules, year-end calculation, time zones, and daylight-saving-time boundaries.

```bash
xcodebuild -project TimeLeft.xcodeproj -scheme 'Time Left Tests' test
```

## Packaging and distribution

Build the Release configuration and run the packaging script:

```bash
xcodebuild -project TimeLeft.xcodeproj -scheme 'Time Left' -configuration Release -derivedDataPath build build
./scripts/package-app.sh "$(pwd)/build/Build/Products/Release/Time Left.app"
```

The script ad-hoc signs the app and widget and creates `dist/Time-Left-<version>.app.zip`. Attach only this ZIP as a GitHub Release asset.

Ad-hoc signing is not Apple Developer ID signing, Hardened Runtime, notarization, or Gatekeeper trust. Public builds need separate Developer ID signing and Apple notarization; never put certificates, private keys, exported `.p12` files, or signing credentials in the repository or a release.

## Project layout

- `TimeLeft` — app lifecycle, menu bar, settings, and schedule management
- `TimeLeftWidget` — WidgetKit extension for shared schedules
- `TimeLeftTests` — countdown calculation tests
- `scripts/package-app.sh` — app-bundle signing and ZIP packaging

## Known limitations

- Widgets refresh on a system-managed schedule, roughly at minute granularity, and therefore may not update at the exact same moment as the menu bar's seconds display.
- A time today or one-time date schedule is completed once its target passes; choose a new target to start another countdown.
- The app checks for newer releases but does not install updates automatically.

## License

Time Left is available under the [MIT License](LICENSE).

Copyright © 2026 Injisung.

## Contributing

Please use [Issues](https://github.com/injisung0818-spec/Time-Left/issues) for bug reports and improvement ideas. Include relevant tests with a proposed change when practical.
