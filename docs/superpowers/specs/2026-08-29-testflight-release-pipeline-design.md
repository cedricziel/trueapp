# TestFlight release pipeline — design

Date: 2026-08-29

## Goal

Every release cut on `main` produces a signed iOS build uploaded to TestFlight,
with no manual steps beyond merging the release PR. Signing assets come from the
existing fastlane `match` repository (`cedricziel/certificates`); credentials
live in 1Password and are copied once into GitHub Actions secrets.

Out of scope: App Store submission, macOS builds, runtime 1Password integration.

## Flow

1. Conventional commits land on `main`.
2. `release-please` (GitHub Action, `release-type: dart`) opens or updates a
   release PR that bumps `version:` in `pubspec.yaml` and `CHANGELOG.md`.
3. Merging the PR tags `vX.Y.Z` and creates a **draft** release. The workflow
   immediately flips it to a published **prerelease** (drafts fire no events and
   have no tag, so no other job can race).
4. The `testflight` job (same workflow run) checks out the tag on `macos-26`,
   installs Flutter 3.47.2 and Ruby 3.3, configures an SSH deploy key for the
   match repo, and runs `bundle exec fastlane beta`.
5. The IPA is attached to the run as an artifact (30 days).

## Components

### `.github/workflows/release-please.yml`

Two jobs:

- `release-please` — `googleapis/release-please-action@v5`, token
  `RELEASE_PLEASE_TOKEN || GITHUB_TOKEN`, then `gh release edit --draft=false
  --prerelease`. Outputs `release_created`, `tag_name`, `version`.
- `testflight` — `needs: release-please`, gated on `release_created == 'true'`.
  Steps: checkout tag (`fetch-depth: 0`, needed for the commit-count build
  number), `subosito/flutter-action@v2` pinned to the same `FLUTTER_VERSION` as
  `ci.yml`, `ruby/setup-ruby@v1` with `bundler-cache`, write
  `MATCH_DEPLOY_KEY` to `~/.ssh/id_ed25519`, `flutter pub get`, `dart run
  build_runner build`, `bundle exec fastlane beta allow_dirty:true
  changelog:"Release <tag>"`, upload `build/*.ipa`.

Secrets consumed: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`,
`MATCH_GIT_URL`, `MATCH_PASSWORD`, `MATCH_KEYCHAIN_PASSWORD`,
`MATCH_DEPLOY_KEY`, `RELEASE_PLEASE_TOKEN`.

### `release-please-config.json` / `.release-please-manifest.json`

`release-type: dart`, `include-component-in-tag: false`,
`bump-minor-pre-major: true`, `draft: true`, `prerelease: true`. Manifest starts
at `0.0.1` (current `pubspec.yaml` version).

### `Gemfile` + `fastlane/`

- `Gemfile`: `fastlane ~> 2.234`, eval `fastlane/Pluginfile`.
- `Appfile`: `app_identifier com.cedricziel.trueapp`, `team_id WPW3QSLZ2F`,
  env overrides as in textfriend.
- `Matchfile`: `git_url` from `MATCH_GIT_URL` (default
  `git@github.com:cedricziel/certificates.git`), `storage_mode git`,
  `app_identifier ["com.cedricziel.trueapp"]`.
- `Fastfile`:
  - constants: `WORKSPACE = "ios/Runner.xcworkspace"`, `SCHEME = "Runner"`,
    `XCODEPROJ = "ios/Runner.xcodeproj"`, `APP_IDENTIFIER`, `OUTPUT_DIR = "build"`.
  - `before_all`: load `.env`, `setup_ci if is_ci`.
  - helpers: `load_app_store_connect_api_key` (verbatim from textfriend),
    `commit_count_build_number`, `pubspec_version` (parses `version:` from
    `pubspec.yaml`, strips any `+build`).
  - `private_lane :build_ios`: `sync_code_signing(type: "appstore", readonly:
    is_ci)`; `update_code_signing_settings(use_automatic_signing: false,
    code_sign_identity: "iPhone Distribution", profile_name: match profile,
    targets: ["Runner"])`; `sh flutter build ios --release --no-codesign
    --build-name=<pubspec_version> --build-number=<commit count>`; `build_app(
    workspace:, scheme:, configuration: "Release", export_method: "app-store",
    output_directory:, output_name: "TrueNASManager.ipa", skip_build_archive:
    false, include_symbols: true, destination: "generic/platform=iOS")`.
  - lanes: `beta` (build_ios + `upload_to_testflight(skip_waiting_for_build_processing:
    true, changelog:)`), `build` (build_ios only), `sync_signing`,
    `bootstrap_signing` (`match appstore readonly:false`), `show_build_number`.
  - `.env.default`: documented placeholders pointing at the 1Password items
    "AppStore Connect: fastlane-ci" and "fastlane-ci: match".
- `.gitignore`: `fastlane/.env`, `fastlane/report.xml`, `fastlane/README.md`,
  `*.ipa`, `*.dSYM.zip`.

### Build/version numbers

- Marketing version: `pubspec.yaml` `version:` (release-please owns it).
- Build number: `git rev-list --count HEAD` at the tag. Monotonic on a linear
  `main`; never committed back.

## Bootstrap (one-time, run by the maintainer)

1. `op read` the ASC key ID / issuer ID / .p8 and the match password into
   `gh secret set` for this repo.
2. `ssh-keygen -t ed25519 -C trueapp-fastlane-match-ci`; add the public key as
   a read-only deploy key on `cedricziel/certificates` via `gh api`; store the
   private key as `MATCH_DEPLOY_KEY`.
3. `MATCH_KEYCHAIN_PASSWORD`: random string. `MATCH_GIT_URL`: the SSH URL.
4. `RELEASE_PLEASE_TOKEN`: fine-grained PAT (contents + pull-requests write on
   this repo) so the release PR triggers CI.
5. `bundle exec fastlane bootstrap_signing` locally to create and commit the
   `AppStore com.cedricziel.trueapp` profile into the match repo. Requires the
   App ID to exist in the developer portal with CloudKit, Push Notifications,
   Keychain Sharing, AutoFill Credential Provider and Access Wi-Fi Info enabled.

## Error handling

- Missing env → `UI.user_error!` with the list of expected variables.
- `testflight` job `timeout-minutes: 90`; `if: always()` on the artifact upload
  so a failed upload still leaves the IPA for inspection.
- `FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT=120`, `_RETRIES=5` for slow runners.

## Verification

- `actionlint` on the workflow; `ruby -c` on the Fastfile.
- `bundle exec fastlane build` locally (after bootstrap) proves signing without
  uploading.
- First real release run watched to green.
