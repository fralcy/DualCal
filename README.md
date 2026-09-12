<p align="center">
  <img src="assets/icon/icon.png" alt="DualCal icon" width="120" />
</p>

<h1 align="center">DualCal</h1>

<p align="center">
  A dual solar/lunar calendar for Vietnam — notes, reminders, holidays, and a soft neumorphic theme.
</p>

<p align="center">
  <a href="https://fralcy.github.io/DualCal/">🔗 Live demo (web)</a>
  ·
  <a href="README.vi.md">Tiếng Việt</a>
</p>

---

## Features

- **Dual calendar** — every day shows both its solar (dương lịch) and lunar (âm lịch) date, computed with a pure-Dart port of the classic Hồ Ngọc Đức algorithm (no lookup tables, no third-party lunar package).
- **Notes & events** — anchor a note to a solar or a lunar date, one-time or yearly-recurring (a lunar-anchored birthday recurs by the lunar calendar every year, not a fixed solar date).
- **Reminders** — pick any number of "days before" offsets plus a specific time of day; real OS notifications on mobile/desktop, an in-app "upcoming" list on web (browsers can't reliably fire notifications from a closed tab).
- **Holidays** — Vietnamese public holidays (Tết and its surrounding days, Giỗ Tổ Hùng Vương, Quốc khánh, …) plus major Vietnamese and international observances, built in and shown on the grid.
- **Vietnamese / English** — fully localized UI, switchable in Settings.
- **Neumorphic theming** — five preset soft-UI palettes (including a dark one), applied consistently across the calendar, modals, and buttons.
- **Backup** — export all notes/settings to a JSON file and re-import later, merging with or replacing existing data.
- **Responsive** — one codebase adapting between a mobile layout (full-screen grid + bottom sheet) and a desktop/web layout (grid + persistent side panel), with keyboard shortcuts (arrow keys, Page Up/Down, Home/T, Enter, Escape) and swipe-to-change-month on touch.

## Tech stack

Flutter (Android/iOS/Windows/macOS/Linux/Web from one codebase), `provider` for state management, `hive` for local persistence (offline-first, no backend), `flutter_local_notifications` + `timezone` for reminders, `intl`/`flutter_localizations` for i18n, `file_picker` for backup import/export.

## Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates Hive adapters (lib/**/*.g.dart)
flutter gen-l10n                                           # generates AppLocalizations (or just run/build — it's automatic)
flutter run
```

Run the test suite with `flutter test` and static analysis with `flutter analyze`.

### Building for web

```bash
flutter build web --release --base-href /DualCal/
```

Pushes to `main` automatically rebuild and redeploy the web build to GitHub Pages via `.github/workflows/deploy-pages.yml`.

### Regenerating the app icon

The source icon lives at `assets/icon/icon.png`. After replacing it, regenerate every platform's icon set with:

```bash
dart run flutter_launcher_icons
```

## Known limitations

- Real device notification delivery (the `flutter_local_notifications` path) has been unit-tested against a fake service but not yet verified on an actual Android/iOS device.
- No signing/store configuration (Android keystore, iOS provisioning) — the project targets the web build and local/dev installs.
- No CI test gate yet (the GitHub Actions workflow only builds and deploys; `flutter test`/`flutter analyze` are run locally before each commit).
