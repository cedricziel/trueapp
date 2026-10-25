# Design

## Context

See proposal.md for why. What shapes the approach:

- The add-server screen (`lib/screens/add_server_screen.dart`) is a
  `StatefulWidget` holding plain `TextEditingController`s for name, host,
  port, and an HTTPS flag. Pre-filling means setting those controllers.
- Added servers come from `ServerRepositoryInterface.serversStream`
  (`Stream<List<NasServer>>`); `NasServer` carries `host`, `port`, `useHttps`
  and an optional `localUrl`.
- Settings toggles today (`TrayProvider`) live in memory only; nothing in the
  app persists a per-device preference yet.
- The Synology probe can reuse `packages/synology_api` (PR #265): its
  `SynologyClient.discover()` is exactly the `SYNO.API.Info` query, and
  `FakeSynologyNas.serve()` gives tests a real socket.
- On the user's network, observed behaviour that the decisions below rely on:
  - TrueNAS SCALE answers `core.ping` with `pong` before login, and rejects
    other methods with `-32001` / errno 207 `ENOTAUTHENTICATED`.
  - TrueNAS advertises `_http._tcp` and `_device-info._tcp` with
    `model=MacPro7,1`.
  - Synology DS923+ advertises `_device-info._tcp` with `model=Xserve` and
    `_smb._tcp`, but no `_http._tcp`.
  - The QuickConnect finder returned the DS923+ with model, DSM version, LAN
    addresses and ports.

## Goals / Non-Goals

**Goals:**

- Discovery logic that is testable without platform channels: sources and
  probes behind interfaces, and the merge, probe and exclusion rules in plain
  Dart.
- A single stream the UI renders, so the screen holds no discovery state of
  its own.

**Non-Goals:**

- Background or periodic discovery, and discovery outside the add-server
  screen.
- Remembering discovered devices between sessions.
- Reading the model from SSDP or the DLNA media server description.

## Decisions

### Three roles behind interfaces

`lib/services/discovery/` holds:

- `DiscoverySource`: `Stream<DiscoveryCandidate> scan()`. A candidate has a
  hostname, addresses, ports and optional hints (model, OS version, display
  name, and a platform guess). Implementations: `BonjourDiscoverySource` and
  `QuickConnectDiscoverySource`.
- `DeviceProbe`: `Future<DeviceIdentity?> probe(DiscoveryCandidate)`, with one
  implementation per platform: `TrueNasProbe` and `SynologyProbe`.
- `DeviceDiscoveryService`: takes the sources, the probes, the server
  repository and a clock. `start()` returns a session exposing
  `Stream<DiscoveryState>` (the device list plus a
  scanning/finished/unavailable status) and `close()`.

The service is the only place that merges, deduplicates, schedules probes and
excludes added servers, so those rules (spec: merging, exclusion, progressive
results) are unit-tested with in-memory fake sources.

Alternative considered: a single class per platform that both finds and
confirms. Rejected, because mDNS finds both platforms at once, and the
QuickConnect source finds Synology only.

### Bonjour through `bonsoir`, not raw multicast

`bonsoir` wraps `NSNetServiceBrowser` on iOS and macOS, so the app needs only
`NSBonjourServices` and `NSLocalNetworkUsageDescription`. Pin a release at
least two weeks old; the latest (7.1.6) was published on 2026-10-25.

Alternatives considered:

- `multicast_dns` is pure Dart, but sends raw multicast. On iOS that needs the
  `com.apple.developer.networking.multicast` entitlement, which Apple grants
  only on request.
- `nsd` covers fewer desktop platforms and offers no advantage on Apple ones.

### Probe order from hints, both probes as fallback

A `model=Xserve` hint tries the Synology probe first, and `MacPro7,1` tries
TrueNAS first. Without a hint, both run. Hints only order the work, and never
identify a device (spec: "mDNS hints alone do not identify a device").

Ports and schemes:

- TrueNAS: `wss` on the advertised `_http._tcp` host at 443, then `ws` at 80
  or the advertised port.
- Synology: `https` 5001, then `http` 5000.

The first success wins and records the scheme and port used, which is what
pre-filling needs.

### Probe limits

- At most 4 probes run at once, and each attempt has a 3-second timeout. A
  home LAN has a dozen `_http._tcp` hosts (chargers, printers, plugs); four
  parallel probes clear that in a few seconds without flooding small devices.
- Probes use a dedicated `HttpClient` that accepts any certificate. It is
  created per session and never shared with the authenticated API clients.
  This is safe because a probe sends no credentials.
- Pre-filling sets HTTPS from the scheme that answered, and leaves "allow
  untrusted certificates" off. Trusting a self-signed certificate stays an
  explicit user choice, and the form's existing connection test reports the
  certificate if it fails.

### Merge key

Candidates merge when any normalised address or hostname overlaps.
Hostnames are lowercased without the trailing dot, and IPv6 link-local
addresses are ignored for matching and display. The merged device keeps the
first non-null value of each hint, with QuickConnect's name, model and version
preferred over mDNS TXT records.

### Exclusion uses hosts the user entered

A device is excluded when its hostname or any address equals an added
server's `host`, or the host of its `localUrl`, compared case-insensitively.
The service listens to `serversStream`, so a server added in another window
drops out of a live session.

### QuickConnect setting persisted with `shared_preferences`

The setting is one boolean that belongs to this device, so it should not sync
through CloudKit like server metadata. Wrap it in a `DiscoverySettings`
interface with a `shared_preferences` implementation, exposed as a stream so
the session reacts when the setting changes.

Alternative considered: a drift table. Rejected because it needs a schema
migration for one flag.

### QuickConnect client

`QuickConnectDiscoverySource` makes two GETs with `package:http`:

- `https://global.quickconnect.to/finder/server`, read
  `syno_finder_site=<host>`, falling back to `global.quickconnect.cn`;
- then `https://<host>/finder/get_v2`.

It maps each entry to a candidate using `ipv4_interface`, `port`,
`https_port`, `server_name`, `model` and `version`, and drops every other
field (including `mac` and `sn`) during parsing, before anything can log it.
Errors end the source quietly; the session keeps the mDNS results.

### UI state through a stream

The add-server screen gets the service from the widget tree, starts a session
in `initState`, renders `StreamBuilder<DiscoveryState>` in a new
`NearbyDevicesSection` widget, and closes the session in `dispose`. Selecting
a TrueNAS device calls back into the screen, which sets the controllers.

### Telemetry

Discovery logs counts and outcomes only: candidates, confirmed devices, probe
failures by reason. It never logs finder payloads. Hostnames and addresses go
through the existing `telemetry_redactor`, like other server addresses.

## Risks / Trade-offs

- **The QuickConnect endpoints are undocumented and may change.** → The source
  fails quietly, the setting is off by default, and mDNS stays the primary
  path.
- **Behind CGNAT or a shared public IP, the finder may return other people's
  devices.** → Every candidate must pass a LAN probe before it is shown, so
  unreachable addresses never appear.
- **The local-network prompt appears the first time the add-server screen
  opens, which may surprise users.** → The usage description says why. A
  denial shows the "local network access is needed" message instead of an
  empty list.
- **Probing a non-NAS `_http._tcp` host sends it a WebSocket upgrade and a
  `query.cgi` request.** → Both are harmless reads, capped at 4 in parallel
  with a 3-second timeout.
- **A SCALE release without `/api/current` is not found.** → It can still be
  added by hand; this matches the supported-releases note in the proposal.
- **`bonsoir` behaviour differs between the simulator and devices.** → PR 2's
  verification runs on a real iPhone and Mac, not only the simulator.

## Migration Plan

No data migration is needed. The work ships as four PRs, each revertable on
its own:

1. Discovery core: models, interfaces, service and probes, with tests only and
   no UI or platform code.
2. `BonjourDiscoverySource`, the Info.plist keys and the `bonsoir` dependency.
3. The Nearby section on the add-server screen.
4. The QuickConnect source, the `DiscoverySettings` toggle in settings, and
   PRIVACY.md.

Rolling back PR 3 hides the feature entirely. PRs 1 and 2 are inert without
it.
