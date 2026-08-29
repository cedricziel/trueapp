# TrueNAS Manager

A Flutter application for managing TrueNAS servers from iOS and macOS devices.

## Features

- **Multi-Server Management**: Register and manage multiple TrueNAS servers
- **Secure Storage**: Credentials live in the native Keychain (biometric unlock); server metadata syncs via CloudKit on Apple platforms and SQLite elsewhere
- **Native UI**: Built with Cupertino widgets for native iOS/macOS experience
- **Server Health Monitoring**: View CPU, memory, disk usage and system stats
- **File Management**: Browse files on your TrueNAS servers
- **App Management**: Browse installed apps, view live resource usage and edit app configuration
- **Storage**: Inspect pools and datasets
- **macOS Menu Bar**: Quick access to servers from the system tray

## Architecture

The app follows a clean architecture pattern with:

- **Models**: Data structures for servers, health metrics, and files
- **Services**: Database layer using drift (SQLite)
- **Providers**: State management using Provider pattern
- **Screens**: UI screens for different app features
- **Widgets**: Reusable UI components

## Tech Stack

- **Flutter**: Cross-platform framework
- **drift**: Type-safe database library (formerly moor)
- **Provider**: State management
- **dio**: HTTP client for API calls
- **flutter_slidable**: Swipe actions for list items

## Getting Started

### Prerequisites

- Flutter SDK 3.47.2 or newer (bundles Dart 3.13.2; `pubspec.yaml` requires Dart 3.9.0+)
- Xcode (for iOS/macOS development)
- CocoaPods

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   # For iOS
   flutter run

   # For macOS
   flutter run -d macos
   ```

## Testing & Coverage

Run the full test suite:
```bash
flutter test
```

Measure coverage locally the same way CI does:
```bash
flutter test --coverage
dart run tool/check_coverage.dart
```

This parses `coverage/lcov.info`, excludes build-generated sources
(`*.g.dart`, `*.freezed.dart`, `*.mocks.dart` - `lib/services/database.g.dart`
is the current example) from the percentage, and fails if coverage drops
below the floor recorded in `tool/coverage_floor.txt`. Generated code is
excluded because nobody writes tests against it, and including it makes the
number reflect how much drift generates rather than how much of the
hand-written app is tested.

The floor is a **ratchet**, not the 80% goal itself: it is set just below the
coverage measured on the branch that introduced the check, so it can only move
up as real coverage improves. It sits a little under the measured number rather
than exactly at it because CI runs on macOS while most local runs are on Linux,
and the app has `Platform.is*` branches whose lines are only reachable on one
host - a floor pinned to the exact local measurement would fail CI for a
platform difference rather than a real regression. Raise it when coverage
rises; never lower it without a written reason.

Two caveats worth knowing when reading the number:
- `packages/truenas_native_plugins/lib` is a separate package and is not
  included in the report at all.
- lcov only contains records for `lib/` files a test actually imported, so
  files nothing exercises are silently absent rather than counted as 0%.
  `tool/check_coverage.dart` prints how many `lib/` files are missing from
  the report for exactly this reason - the headline percentage is
  optimistic, not exact.

No coverage badge is published: every option (Codecov, Coveralls, a shields
endpoint) needs an external service and a repository secret, which isn't
justified yet. CI uploads `coverage/lcov.info` as a build artifact instead,
so the report is inspectable per run.

## Project Structure

```
lib/
├── models/          # Data models
├── services/        # Database and API services
├── providers/       # State management
├── screens/         # UI screens
├── widgets/         # Reusable widgets
└── main.dart        # App entry point
```

## Development Status

### Completed
- ✅ Project setup and architecture
- ✅ Multi-server management (add, edit, delete, default server)
- ✅ TrueNAS JSON-RPC API client with keepalive (ping/pong)
- ✅ Repository layer with CloudKit sync on Apple platforms and SQLite elsewhere
- ✅ Secure credential storage via native Keychain with biometric unlock
- ✅ Storage pools and dataset browsing
- ✅ App catalog: list, detail, configuration and live resource usage
- ✅ File browsing
- ✅ System stats and server health view
- ✅ Connection status / network awareness
- ✅ macOS menu bar (tray) integration
- ✅ Native plugins extracted into the reusable `truenas_native_plugins` package
- ✅ Adaptive Cupertino sidebar navigation with go_router ([#54](https://github.com/cedricziel/trueapp/issues/54))

### In Progress
- 🚧 Breaking large screens into smaller reusable widgets ([#35](https://github.com/cedricziel/trueapp/issues/35))
- 🚧 Raising test coverage towards the 80% goal

### Planned
- 📋 Real-time alerts with push notifications ([#25](https://github.com/cedricziel/trueapp/issues/25))
- 📋 Job/task monitor with progress tracking ([#26](https://github.com/cedricziel/trueapp/issues/26))
- 📋 Service management (start/stop/restart) ([#27](https://github.com/cedricziel/trueapp/issues/27))
- 📋 Customizable dashboard with widgets ([#28](https://github.com/cedricziel/trueapp/issues/28))
- 📋 System update management ([#29](https://github.com/cedricziel/trueapp/issues/29))
- 📋 Network interface management ([#30](https://github.com/cedricziel/trueapp/issues/30))
- 📋 Pool health and scrub monitoring ([#31](https://github.com/cedricziel/trueapp/issues/31))
- 📋 Server discovery wizard with mDNS ([#39](https://github.com/cedricziel/trueapp/issues/39))
- 📋 File upload/download
- 📋 App Store / TestFlight distribution ([#16](https://github.com/cedricziel/trueapp/issues/16), [#51](https://github.com/cedricziel/trueapp/issues/51))

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
