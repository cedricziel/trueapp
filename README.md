# TrueNAS Manager

A Flutter application for managing TrueNAS servers from iOS and macOS devices.

## Features

- **Multi-Server Management**: Register and manage multiple TrueNAS servers
- **Secure Storage**: Server credentials are stored locally using encrypted SQLite database
- **Native UI**: Built with Cupertino widgets for native iOS/macOS experience
- **Server Health Monitoring**: View CPU, memory, disk usage, and temperatures (coming soon)
- **File Management**: Browse and manage files on your TrueNAS servers (coming soon)

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

- Flutter SDK (3.8.0 or higher)
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
- ✅ Server management (add, edit, delete)
- ✅ Local database integration
- ✅ Basic navigation and UI

### In Progress
- 🚧 TrueNAS API integration
- 🚧 File browsing functionality
- 🚧 Server health monitoring

### Planned
- 📋 Real-time server metrics
- 📋 File upload/download
- 📋 Push notifications for alerts
- 📋 Dark mode support

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
