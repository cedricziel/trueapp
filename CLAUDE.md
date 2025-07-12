# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TrueNAS Manager - A Flutter application for managing TrueNAS servers on iOS and macOS platforms using native Cupertino design.

## Commands

### Development
- `flutter pub get` - Install dependencies
- `flutter run` - Run on iOS (default)
- `flutter run -d macos` - Run on macOS
- `flutter analyze` - Run static analysis
- `dart run build_runner build` - Generate database code (required after modifying database schema)
- `dart format` - Run dart formatter before committing

### Building
- `flutter build ios` - Build iOS app
- `flutter build macos` - Build macOS app

### Testing
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run specific test file

## Architecture

### State Management
Uses Provider pattern. Providers are located in `lib/providers/` and manage application state:
- `server_provider.dart` - Manages server connections and active server state
- `pool_provider.dart` - Manages storage pool data
- `dataset_provider.dart` - Manages dataset information

### Data Layer
Repository pattern with drift (SQLite) database:
- `lib/services/database_service.dart` - Main database service using drift
- `lib/models/` - Data models using Equatable for value equality
- Database schema changes require running `dart run build_runner build`

### UI Structure
- `lib/screens/` - Full page views (e.g., server list, pool details, dataset management)
- `lib/widgets/` - Reusable UI components
- All UI uses Cupertino (iOS-style) widgets exclusively

### Key Implementation Notes
1. The app supports multiple TrueNAS server connections stored securely in SQLite
2. API credentials are stored in the database (consider security implications)
3. Uses dio for HTTP requests to TrueNAS API
4. Native platform features through iOS/macOS specific implementations

## Current Development Status
According to README.md:
- ✅ Completed: Basic UI, server management, navigation
- 🚧 In Progress: Pool management UI, dataset operations
- 📋 Planned: Snapshot management, user management, system monitoring

When implementing new features, follow the existing patterns and ensure compatibility with both iOS and macOS platforms.

## Tooling Notes
- `gtimeout` is used for adding timeouts to bash commands

## Development Philosophy
- We want to use best-practices like coding against interfaces, dependency injection etc whenever we can and it's our responsibility to gradually modernize the parts of the app we touch
- We want to build smaller, more manageable components when new functionality is added, and consider refactoring chunks into smaller components when we touch them
- We want to code against interfaces so testing is easier and abstractions for other platforms are easier
- Flutter embraces reactivity - being reactive to state-changes with patterns of streaming is what we want to do

## Test Development Guidelines
- When writing or changing tests, ensure they are following SOLID principles - even if it means we need new interfaces or refactorings

## Testing Goals
- We aim for 80% coverage

## Dart Language Notes
- We want to make use of dart's ability to trim down files with part of