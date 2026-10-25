# Tasks

Prerequisites: PR #265 (`packages/synology_api`) and PR #267 (TrueNAS fake
with login checks and `emit`) are merged.

## 1. Discovery core (PR 1: no UI, no platform code)

- [ ] 1.1 Add `DiscoveryCandidate`, `DeviceIdentity`, `DiscoveredDevice` and `DiscoveryState` models in `lib/services/discovery/`; prove with `test/services/discovery/models_test.dart` covering hostname and address normalisation (lowercase, trailing dot, IPv6 link-local ignored)
- [ ] 1.2 Add the `DiscoverySource` and `DeviceProbe` interfaces, plus an in-memory `FakeDiscoverySource` in `test/helpers/`; prove by `flutter analyze` and the fake's use in 1.4
- [ ] 1.3 Implement `TrueNasProbe` (`core.ping` over `/api/current`, `wss` then `ws`, 3 s timeout, any-certificate `HttpClient`); prove with failing tests against `FakeTrueNasServer`: identified on `pong`, not identified on a plain HTTP server, gives up after the timeout
- [ ] 1.4 Implement `SynologyProbe` on `SynologyClient.discover()` (5001 then 5000); prove with failing tests against `FakeSynologyNas.serve()`: identified with the port that answered, not identified when `query.cgi` is missing
- [ ] 1.5 Implement `DeviceDiscoveryService` merging by overlapping address or hostname, one probe per device, hint-based probe order, at most 4 probes in parallel; prove with failing tests for the merging scenarios, including "one device announced under several service types" probed once
- [ ] 1.6 Publish progressively and exclude added servers from `serversStream`, including `localUrl` hosts; prove with failing tests for "first device shown before the scan finishes", "configured server not offered again", and a server added mid-session dropping out
- [ ] 1.7 Session lifecycle: `close()` stops sources and outstanding probes, and a source reporting permission denial yields the `unavailable` status; prove with failing tests for "session end stops the scan" and "local network access denied"
- [ ] 1.8 Run `flutter analyze`, `dart format --set-exit-if-changed .`, `flutter test --coverage` and `dart run tool/check_coverage.dart`, then `/simplify`, and open PR 1

## 2. Bonjour source (PR 2)

- [ ] 2.1 Add `bonsoir`, pinned to a release at least two weeks old, and verify `flutter pub get` and both platform builds succeed
- [ ] 2.2 Implement `BonjourDiscoverySource` browsing `_device-info._tcp`, `_http._tcp` and `_smb._tcp`, mapping resolved services and TXT `model` to candidates behind a thin adapter interface; prove with failing unit tests that feed recorded resolve events (the `hive`, `truenas-2` and `harpalyke` records from the design) through a fake adapter
- [ ] 2.3 Add `NSLocalNetworkUsageDescription` and `NSBonjourServices` to `ios/Runner/Info.plist` and `macos/Runner/Info.plist`; verify with `plutil -lint` and a test that reads both plists and asserts the three service types
- [ ] 2.4 Verify on a real iPhone and Mac on a LAN with a TrueNAS and a Synology box that the prompt appears once and both boxes become candidates (manual; note the result in the PR)
- [ ] 2.5 Run the checks from 1.8 and `/simplify`, and open PR 2

## 3. Nearby section (PR 3)

- [ ] 3.1 Provide `DeviceDiscoveryService` through `app_providers.dart` with the Bonjour source and both probes; verify the app starts and `flutter analyze` is clean
- [ ] 3.2 Add the `NearbyDevicesSection` widget rendering `DiscoveryState` (scanning, list, nothing found, unavailable); prove with failing widget tests for "devices appear while scanning", "nothing found" and "scan unavailable"
- [ ] 3.3 Wire the section into `add_server_screen.dart`, starting the session in `initState` and closing it in `dispose`; prove with a failing widget test that the session closes when the screen is popped
- [ ] 3.4 Selecting a TrueNAS device fills name, host, port and HTTPS, and leaves credentials and the untrusted-certificate toggle unchanged; prove with a failing widget test for "selecting a device"
- [ ] 3.5 Show Synology devices disabled with "not supported yet"; prove with a failing widget test that tapping one leaves the form unchanged
- [ ] 3.6 Run the checks from 1.8, check the screen in light and dark mode on iPhone and Mac, run `/simplify`, and open PR 3

## 4. QuickConnect lookup (PR 4)

- [ ] 4.1 Add the `DiscoverySettings` interface with a `shared_preferences` implementation exposing the opt-in as a stream, default off; prove with failing tests for the default and persistence across instances
- [ ] 4.2 Implement `QuickConnectDiscoverySource` (finder site, then `get_v2`, `.cn` fallback, keeping only the mapped fields); prove with failing tests on a `MockClient` replaying the recorded DS923+ reply: candidate with model `DS923+` and version `7.4.1-90080`, and no `mac` or `sn` in the candidate or in captured log output
- [ ] 4.3 Have the service include the source only while the setting is on; prove with failing tests for "off by default" (no request made) and "lookup failure does not break the scan"
- [ ] 4.4 Merge QuickConnect hints into mDNS results for the same address; prove with a failing test for "mDNS and cloud results for the same box"
- [ ] 4.5 Add the setting to `settings_screen.dart` with a subtitle naming Synology and the public IP; prove with a failing widget test that toggling it updates `DiscoverySettings`
- [ ] 4.6 Update PRIVACY.md with the local scan and the optional Synology lookup, and verify the text against the spec's privacy requirement
- [ ] 4.7 Run the checks from 1.8 and `/simplify`, and open PR 4

## 5. Close out

- [ ] 5.1 Run `openspec validate add-lan-device-discovery --strict` and archive the change as the last commit on the final PR's branch
