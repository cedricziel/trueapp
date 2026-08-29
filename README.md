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
- **fl_chart**: Charts for health monitoring

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

## Releasing

Releases are cut by [release-please](https://github.com/googleapis/release-please)
from conventional commits on `main`:

1. Merging commits to `main` opens or updates a release PR that bumps
   `version:` in `pubspec.yaml` and `CHANGELOG.md`.
2. Merging the release PR tags `vX.Y.Z`, publishes a GitHub prerelease, and
   the `Upload to TestFlight` job builds a signed iOS IPA with
   [fastlane](https://fastlane.tools) and uploads it to TestFlight.

The build number is the commit count at the tag; the marketing version comes
from `pubspec.yaml`. Signing assets live in a private fastlane `match`
repository. To build locally:

```bash
bundle install
cp fastlane/.env.default fastlane/.env   # fill in from 1Password
bundle exec fastlane build               # signed IPA in build/, no upload
bundle exec fastlane beta                # build + upload to TestFlight
```

Setting up CI secrets for a fresh fork is a one-time run of
`scripts/bootstrap-release-secrets.sh`.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
