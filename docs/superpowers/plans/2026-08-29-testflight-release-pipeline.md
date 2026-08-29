# TestFlight Release Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every release-please release on `main` uploads a signed iOS build to TestFlight without manual steps.

**Architecture:** release-please owns the marketing version in `pubspec.yaml` and cuts tags/prereleases; a `testflight` job in the same workflow runs a fastlane `beta` lane that syncs signing via `match`, builds with Flutter, archives with `build_app`, and uploads with `upload_to_testflight`. The build number is the commit count at the tag.

**Tech Stack:** GitHub Actions (`macos-26`), release-please-action v5 (`dart` release type), fastlane ~> 2.234 (match, gym, pilot), Flutter 3.47.2, Ruby 3.3.

**Spec:** `docs/superpowers/specs/2026-08-29-testflight-release-pipeline-design.md`

## Global Constraints

- Flutter version pinned to `3.47.2` in every workflow (single `FLUTTER_VERSION` env per file, matches `ci.yml`).
- Bundle ID `com.cedricziel.trueapp`, team `WPW3QSLZ2F`.
- Match repo `git@github.com:cedricziel/certificates.git`, storage mode `git`.
- Secrets: `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT`, `MATCH_GIT_URL`, `MATCH_PASSWORD`, `MATCH_KEYCHAIN_PASSWORD`, `MATCH_DEPLOY_KEY`, `RELEASE_PLEASE_TOKEN`.
- No App Store submission, no macOS build.
- Commit messages: conventional commits; the repo's `dart_pre_commit` hook fails on pre-existing outdated deps — commit non-Dart files with `--no-verify`.

---

### Task 1: release-please configuration

**Files:**
- Create: `release-please-config.json`
- Create: `.release-please-manifest.json`

**Interfaces:**
- Produces: tag format `vX.Y.Z`, `pubspec.yaml` `version:` bumped by release-please, draft prerelease on release creation. Task 4's workflow consumes `config-file`/`manifest-file` paths.

- [ ] **Step 1: Write config**

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "packages": {
    ".": {
      "release-type": "dart",
      "include-component-in-tag": false,
      "bump-minor-pre-major": true,
      "bump-patch-for-minor-pre-major": false,
      "draft": true,
      "prerelease": true
    }
  }
}
```

- [ ] **Step 2: Write manifest** — `{ ".": "0.0.1" }` (must equal the current `pubspec.yaml` version without `+build`).

- [ ] **Step 3: Verify** — `python3 -c 'import json;json.load(open("release-please-config.json"));json.load(open(".release-please-manifest.json"))'` and `grep '^version:' pubspec.yaml` shows `0.0.1+1`.

- [ ] **Step 4: Commit** — `git commit --no-verify -m "chore: configure release-please for dart releases"`.

### Task 2: pubspec version helper (TDD)

**Files:**
- Create: `fastlane/lib/pubspec_version.rb`
- Test: `fastlane/test/pubspec_version_test.rb`

**Interfaces:**
- Produces: `PubspecVersion.read(path) -> String` returning the marketing version with any `+build` suffix stripped; raises `ArgumentError` when no `version:` line exists. Task 3's Fastfile calls `PubspecVersion.read("../pubspec.yaml")`.

- [ ] **Step 1: Write the failing test**

```ruby
require "minitest/autorun"
require "tempfile"
require_relative "../lib/pubspec_version"

class PubspecVersionTest < Minitest::Test
  def with_pubspec(content)
    Tempfile.create(["pubspec", ".yaml"]) do |f|
      f.write(content)
      f.flush
      yield f.path
    end
  end

  def test_strips_build_suffix
    with_pubspec("name: x\nversion: 1.2.3+45\n") { |p| assert_equal "1.2.3", PubspecVersion.read(p) }
  end

  def test_plain_version
    with_pubspec("version: 0.0.1\n") { |p| assert_equal "0.0.1", PubspecVersion.read(p) }
  end

  def test_missing_version_raises
    with_pubspec("name: x\n") { |p| assert_raises(ArgumentError) { PubspecVersion.read(p) } }
  end
end
```

- [ ] **Step 2: Run** `ruby fastlane/test/pubspec_version_test.rb` — expect LoadError (file missing).

- [ ] **Step 3: Implement**

```ruby
# Reads the marketing version from a Flutter pubspec.yaml.
# "version: 1.2.3+45" -> "1.2.3"; the +build part is owned by CI.
module PubspecVersion
  VERSION_LINE = /^version:\s*(\d+\.\d+\.\d+)(?:\+\S+)?\s*$/

  def self.read(path)
    File.foreach(path) do |line|
      return Regexp.last_match(1) if line.match?(VERSION_LINE) && line =~ VERSION_LINE
    end
    raise ArgumentError, "No 'version: x.y.z' line found in #{path}"
  end
end
```

- [ ] **Step 4: Run** the test again — expect 3 runs, 0 failures.

- [ ] **Step 5: Commit** — `git commit --no-verify -m "feat(fastlane): add pubspec version reader"`.

### Task 3: fastlane setup

**Files:**
- Create: `Gemfile`, `fastlane/Pluginfile`, `fastlane/Appfile`, `fastlane/Matchfile`, `fastlane/Fastfile`, `fastlane/.env.default`
- Modify: `.gitignore` (append fastlane/build entries)

**Interfaces:**
- Consumes: `PubspecVersion.read` (Task 2).
- Produces: lanes `beta`, `build`, `sync_signing`, `bootstrap_signing`, `show_build_number`; env contract `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_CONTENT|ASC_KEY_PATH`, `MATCH_GIT_URL`, `MATCH_PASSWORD`. IPA at `build/TrueNASManager.ipa`. Task 4 runs `bundle exec fastlane beta allow_dirty:true changelog:"..."`.

- [ ] **Step 1: Gemfile**

```ruby
source "https://rubygems.org"

gem "fastlane", "~> 2.234"

# Dependabot's bundler parser only accepts a string-literal argument here.
eval_gemfile "fastlane/Pluginfile"
```

`fastlane/Pluginfile`: the three-line autogenerated header comment only.

- [ ] **Step 2: Appfile / Matchfile**

```ruby
# Appfile
app_identifier(ENV["APP_IDENTIFIER"] || "com.cedricziel.trueapp")
apple_id(ENV["FASTLANE_APPLE_ID"]) if ENV["FASTLANE_APPLE_ID"]
itc_team_id(ENV["ITC_TEAM_ID"]) if ENV["ITC_TEAM_ID"]
team_id(ENV["FASTLANE_TEAM_ID"] || "WPW3QSLZ2F")
```

```ruby
# Matchfile
git_url(ENV["MATCH_GIT_URL"] || "git@github.com:cedricziel/certificates.git")
storage_mode("git")
type("appstore")
app_identifier(["com.cedricziel.trueapp"])
git_branch(ENV["MATCH_GIT_BRANCH"]) if ENV["MATCH_GIT_BRANCH"]
username(ENV["FASTLANE_APPLE_ID"]) if ENV["FASTLANE_APPLE_ID"]
```

- [ ] **Step 3: Fastfile** — full content lives in the implementation; structure:
  - `opt_out_usage`, `default_platform(:ios)`, `require_relative "lib/pubspec_version"`.
  - Constants `WORKSPACE = "ios/Runner.xcworkspace"`, `XCODEPROJ = "ios/Runner.xcodeproj"`, `SCHEME = "Runner"`, `APP_IDENTIFIER = "com.cedricziel.trueapp"`, `TEAM_ID = "WPW3QSLZ2F"`, `OUTPUT_DIR = "build"`, `IPA_NAME = "TrueNASManager.ipa"`.
  - `commit_count_build_number` (`git rev-list --count HEAD`), `marketing_version` (`PubspecVersion.read("../pubspec.yaml")`).
  - `before_all`: `Dotenv.load(".env")`, `setup_ci if is_ci`.
  - `load_app_store_connect_api_key` copied verbatim from textfriend.
  - `private_lane :build_ios`: `sync_code_signing(type: "appstore", readonly: is_ci, api_key:)`, `update_code_signing_settings(use_automatic_signing: false, path: XCODEPROJ, team_id: TEAM_ID, code_sign_identity: "iPhone Distribution", profile_name: ENV["sigh_#{APP_IDENTIFIER}_appstore_profile-name"] || "match AppStore #{APP_IDENTIFIER}", targets: ["Runner"])`, `Dir.chdir("..") { sh("flutter", "build", "ios", "--release", "--no-codesign", "--build-name=#{marketing_version}", "--build-number=#{commit_count_build_number}") }`, `build_app(workspace: WORKSPACE, scheme: SCHEME, configuration: "Release", export_method: "app-store", output_directory: OUTPUT_DIR, output_name: IPA_NAME, include_symbols: true, include_bitcode: false, destination: "generic/platform=iOS", export_options: { provisioningProfiles: { APP_IDENTIFIER => "match AppStore #{APP_IDENTIFIER}" } })`.
  - Lanes `beta` (ensure_git_status_clean unless allow_dirty; build_ios; `upload_to_testflight(api_key:, app_identifier:, skip_waiting_for_build_processing: true, changelog:)`), `build`, `sync_signing`, `bootstrap_signing` (`match(type: "appstore", readonly: false)`), `show_build_number`, `error do ... end`.

- [ ] **Step 4: `.env.default`** — commented placeholders referencing 1Password items "AppStore Connect: fastlane-ci" and "fastlane-ci: match".

- [ ] **Step 5: `.gitignore`** — append `fastlane/.env`, `fastlane/report.xml`, `fastlane/README.md`, `*.ipa`, `*.dSYM.zip`.

- [ ] **Step 6: Verify** — `ruby -c fastlane/Fastfile fastlane/Appfile fastlane/Matchfile Gemfile` all "Syntax OK"; `bundle install` succeeds; `bundle exec fastlane lanes` lists the five lanes.

- [ ] **Step 7: Commit** — `git commit --no-verify -m "feat(fastlane): add TestFlight beta lane with match signing"`.

### Task 4: release workflow

**Files:**
- Create: `.github/workflows/release-please.yml`

**Interfaces:**
- Consumes: Task 1 config paths; Task 3 `fastlane beta`; secrets list from Global Constraints.

- [ ] **Step 1: Write workflow** — jobs `release-please` (ubuntu, `push` to main, publishes draft as prerelease) and `testflight` (`macos-26`, `needs: release-please`, `if release_created == 'true'`, checkout tag with `fetch-depth: 0`, `subosito/flutter-action@v2` at `FLUTTER_VERSION: '3.47.2'`, `ruby/setup-ruby@v1` ruby 3.3 `bundler-cache: true`, SSH deploy key, `flutter pub get`, `dart run build_runner build --delete-conflicting-outputs`, `bundle exec fastlane beta allow_dirty:true changelog:"Release <tag>"`, upload `build/*.ipa` artifact `if: always()`). `permissions: contents: write, pull-requests: write`. `timeout-minutes: 90`.

- [ ] **Step 2: Verify** — `actionlint .github/workflows/release-please.yml` (install via `brew install actionlint` if absent) reports nothing.

- [ ] **Step 3: Commit** — `git commit --no-verify -m "ci: upload TestFlight build on release-please releases"`.

### Task 5: bootstrap script for the maintainer

**Files:**
- Create: `scripts/bootstrap-release-secrets.sh`

**Interfaces:**
- Produces: idempotent script that reads 1Password items, generates the deploy key, registers it on `cedricziel/certificates`, and sets all GitHub secrets except `RELEASE_PLEASE_TOKEN` (printed as a manual step).

- [ ] **Step 1: Write script** — `set -euo pipefail`; requires `op`, `gh`, `ssh-keygen`; `op read` for `ASC_KEY_ID` (`Benutzername`), `ASC_ISSUER_ID`, `.p8` document, `MATCH_PASSWORD`; `openssl rand -base64 32` for `MATCH_KEYCHAIN_PASSWORD`; `ssh-keygen -t ed25519 -N "" -C trueapp-fastlane-match-ci -f "$tmp/key"`; `gh api repos/cedricziel/certificates/keys -f title=trueapp-fastlane-match-ci -f key="$(cat key.pub)" -F read_only=true`; `gh secret set` for each; final echo about `RELEASE_PLEASE_TOKEN` and `bundle exec fastlane bootstrap_signing`.

- [ ] **Step 2: Verify** — `bash -n scripts/bootstrap-release-secrets.sh`; `shellcheck` if available.

- [ ] **Step 3: Commit** — `git commit --no-verify -m "chore: add release secrets bootstrap script"`.

### Task 6: docs

**Files:**
- Modify: `README.md` (add a "Releasing" section: how releases are cut, what the bootstrap needs).

- [ ] **Step 1: Write section**, **Step 2: Commit** — `docs: describe the release process`.
