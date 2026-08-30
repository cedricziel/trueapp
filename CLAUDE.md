# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TrueNAS Manager - A Flutter application for managing TrueNAS servers on iOS and macOS platforms using native Cupertino design.

## Commands

- `dart run build_runner build` - required after modifying the drift database schema
- `dart format` - run before committing

## Git Conventions
- Always use semantic commits (e.g. `fix:`, `feat:`, `test:`, `refactor:`, `chore:`) for commit messages
- Always use semantic PR titles (e.g. `fix:`, `feat:`, `test:`, `refactor:`, `chore:`)

## Key Implementation Notes

1. All UI uses Cupertino (iOS-style) widgets exclusively - never Material
2. Passwords live in the native Keychain via `NativeKeychainService`, never in the
   database. Server metadata, including the username, is stored by the repository
   layer: CloudKit on Apple platforms, SQLite elsewhere

## Tooling Notes
- `gtimeout` is used for adding timeouts to bash commands
- `.claude/settings.json` enables the `common@cedricziel` Claude Code plugin
  (from `cedricziel/claude-plugins`), which auto-formats edited files via
  `dart format` on save

## Development Philosophy
- We want to use best-practices like coding against interfaces, dependency injection etc whenever we can and it's our responsibility to gradually modernize the parts of the app we touch
- We want to build smaller, more manageable components when new functionality is added, and consider refactoring chunks into smaller components when we touch them
- We want to code against interfaces so testing is easier and abstractions for other platforms are easier
- Flutter embraces reactivity - being reactive to state-changes with patterns of streaming is what we want to do

## Test Development Guidelines
- When writing or changing tests, ensure they are following SOLID principles - even if it means we need new interfaces or refactorings

## Testing Goals
- We aim for 80% coverage
- CI enforces a coverage ratchet (not yet 80%) via `dart run tool/check_coverage.dart`; see the README's "Testing & Coverage" section for how it works and what it excludes

## Dart Language Notes
- We want to make use of dart's ability to trim down files with part of

## Utilities
- We want to create shared test utilities that work in many contexts
