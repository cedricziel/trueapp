# Spec Delta

## Purpose

Finds TrueNAS SCALE and Synology DSM devices on the local network without
credentials, so the app can offer them when the user adds a server.

## ADDED Requirements

### Requirement: Local network scan

While a discovery session is active, the system SHALL browse the local network
over mDNS for the `_device-info._tcp`, `_http._tcp` and `_smb._tcp` service
types and treat each resolved host as a discovery candidate. Discovery SHALL
stop when the session ends.

#### Scenario: Hosts announced over mDNS become candidates

- **WHEN** a discovery session starts on a network where host `truenas-2.local` advertises `_http._tcp` and `_device-info._tcp`
- **THEN** `truenas-2.local` becomes a candidate with the addresses and ports its records resolve to

#### Scenario: Session end stops the scan

- **WHEN** the discovery session ends
- **THEN** the system stops browsing and stops probing outstanding candidates

#### Scenario: Local network access denied

- **WHEN** the user has denied the app local network access
- **THEN** the session reports that the scan is unavailable instead of an empty result, and the add-server flow keeps working

### Requirement: Candidates are confirmed by an unauthenticated probe

The system SHALL report a candidate as a discovered device only after a probe
that sends no credentials identifies it as TrueNAS or Synology. Candidates
that no probe identifies SHALL NOT be reported. The probe SHALL accept
self-signed TLS certificates and SHALL give up on a candidate after 3 seconds.

#### Scenario: TrueNAS SCALE identified by ping (SCALE 25.10)

- **WHEN** a candidate accepts a WebSocket at `/api/current` and answers `core.ping` with `pong`
- **THEN** the system reports a TrueNAS device with that host, port and scheme

#### Scenario: Synology identified by API catalog (DSM 6.2 and 7.x)

- **WHEN** a candidate answers `SYNO.API.Info` `query` on `/webapi/query.cgi` at port 5000 or 5001 with `success: true`
- **THEN** the system reports a Synology device with that host and the ports that answered

#### Scenario: Unidentified host is not reported

- **WHEN** a candidate, such as a printer advertising `_http._tcp`, answers neither probe within 3 seconds
- **THEN** no device is reported for it

#### Scenario: mDNS hints alone do not identify a device

- **WHEN** a candidate advertises `_device-info._tcp` with `model=MacPro7,1` but fails the TrueNAS probe
- **THEN** no device is reported for it

### Requirement: Results are merged per device

The system SHALL merge candidates that share an IP address or hostname into
one device, combining the information each source provides, and SHALL probe
each device at most once per session.

#### Scenario: One device announced under several service types

- **WHEN** host `hive.local` advertises `_http._tcp`, `_device-info._tcp` and `_smb._tcp`
- **THEN** exactly one device is reported for `hive.local`, and it is probed once

#### Scenario: mDNS and cloud results for the same box

- **WHEN** the QuickConnect lookup reports a device at `192.168.178.41` and mDNS resolves `harpalyke.local` to `192.168.178.41`
- **THEN** one device is reported, with the name, model and DSM version from the lookup

### Requirement: Results arrive progressively

The system SHALL publish the current list of discovered devices each time a
device is confirmed or updated, rather than only when the scan completes.

#### Scenario: First device shown before the scan finishes

- **WHEN** one candidate is confirmed while others are still being probed
- **THEN** the published list contains the confirmed device without waiting for the other probes

### Requirement: Already-added servers are excluded

The system SHALL leave out of the published list any device whose host matches
the host of a server the user has already added, and SHALL update the list
when the set of added servers changes.

#### Scenario: Configured server not offered again

- **WHEN** the user has added a server with host `hive.local` and discovery confirms `hive.local`
- **THEN** `hive.local` does not appear in the published list

### Requirement: Optional Synology QuickConnect lookup

The system SHALL offer a setting, off by default, that adds Synology's
QuickConnect finder as a discovery source. When the setting is on, the system
SHALL ask the finder for its regional site and then for the devices it knows
behind the user's public IP, and SHALL treat each returned LAN address as a
candidate. When the setting is off, the system SHALL NOT contact Synology's
servers. The system SHALL discard device MAC addresses and serial numbers from
the reply without storing or logging them.

#### Scenario: Off by default

- **WHEN** the app is newly installed and a discovery session runs
- **THEN** no request is sent to `quickconnect.to`

#### Scenario: Lookup adds model and version (DSM 7.4.1)

- **WHEN** the setting is on and the finder returns a device with model `DS923+`, version `7.4.1-90080` and IPv4 address `192.168.178.41`
- **THEN** `192.168.178.41` becomes a candidate carrying that model and version, and it is still confirmed by the Synology probe before it is reported

#### Scenario: Lookup failure does not break the scan

- **WHEN** the setting is on and the finder cannot be reached
- **THEN** the mDNS results are still reported

#### Scenario: Identifiers are not kept

- **WHEN** the finder reply contains `mac` and `sn` fields
- **THEN** neither value appears in stored data, logs or telemetry
