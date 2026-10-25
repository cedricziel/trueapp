# Proposal

## Why

Adding a server means typing its host, port and HTTPS setting by hand, which
is error-prone and the most common place a new user gets stuck. The NAS boxes
on a home network already announce themselves, and both TrueNAS SCALE and
Synology DSM answer an identifying call without credentials, so the app can
find them and fill in the form.

## What Changes

- The app scans the local network for NAS devices while the add-server screen
  is open, using the system Bonjour (mDNS) browser.
- Every candidate is confirmed by an unauthenticated probe before it is shown:
  `core.ping` on `/api/current` for TrueNAS, `SYNO.API.Info` on `query.cgi`
  for Synology. Candidates that fail the probe are not shown.
- A "Nearby" section at the top of the add-server screen lists confirmed
  devices as they are found, and hides servers the user has already added.
- Tapping a TrueNAS device fills in name, host, port and HTTPS; the user only
  enters credentials. Synology devices appear but are disabled and labelled
  "not supported yet", since the app cannot manage DSM.
- A new, off-by-default setting lets the user also ask Synology's QuickConnect
  finder service which Synology devices it knows behind the user's public IP.
  That adds model and DSM version for boxes that do not advertise over mDNS.
- iOS and macOS gain the Bonjour service declarations and the local-network
  usage description that the permission prompt needs.
- PRIVACY.md describes the local scan and the optional Synology lookup.

Out of scope: SSDP discovery, model artwork, adding Synology servers, and
discovery anywhere outside the add-server screen.

## Supported releases

- TrueNAS SCALE: releases that serve the JSON-RPC API at `/api/current`
  (24.10 and later). A box that does not serve it fails the probe and is not
  listed; the user can still add it by hand.
- Synology DSM: 6.2 and 7.x, both of which serve `SYNO.API.Info` on
  `query.cgi`. Listing only; adding stays unsupported.

## Permissions and third-party data

- New `NSLocalNetworkUsageDescription` and `NSBonjourServices`
  (`_device-info._tcp`, `_http._tcp`, `_smb._tcp`) in the iOS and macOS
  Info.plist. iOS shows the local-network prompt the first time the
  add-server screen scans. No multicast entitlement is needed, since browsing
  goes through the system Bonjour API.
- The local scan sends nothing off the network.
- With the QuickConnect setting on, the app contacts Synology's servers
  (`global.quickconnect.to` and the regional site it names). Synology sees the
  user's public IP address. The reply contains device MAC addresses and serial
  numbers, which the app discards without storing or logging them.
  PRIVACY.md gains a paragraph for both points.

## Capabilities

### New Capabilities

- `device-discovery`: finding NAS devices on the local network, confirming
  each one, merging results from several sources, and the optional Synology
  cloud lookup with its setting.
- `add-server-nearby`: the "Nearby" section of the add-server screen and how
  choosing a discovered device fills in the form.

### Modified Capabilities

None. No specs exist yet.

## Impact

- New code under `lib/services/discovery/` (models, sources, probes, service)
  and a provider for the add-server screen.
- `lib/screens/add_server_screen.dart` gains the Nearby section.
- `lib/screens/settings_screen.dart` gains the QuickConnect setting, which
  needs persistent storage (current settings toggles are in-memory only).
- New dependency on a Bonjour browsing plugin, and on `packages/synology_api`
  (PR #265) for the Synology probe.
- `ios/Runner/Info.plist`, `macos/Runner/Info.plist`, `PRIVACY.md`.
- Tests use `FakeTrueNasServer` (test/helpers) and `FakeSynologyNas`
  (`package:synology_api/testing.dart`).
