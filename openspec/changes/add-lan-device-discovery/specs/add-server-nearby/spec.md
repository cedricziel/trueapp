# Spec Delta

## Purpose

Shows NAS devices discovered on the local network at the top of the
add-server screen, so the user can pick one instead of typing its address.

## ADDED Requirements

### Requirement: Nearby section on the add-server screen

The add-server screen SHALL show a "Nearby" section above the form while it
is open. The section SHALL start a discovery session when the screen opens,
end it when the screen closes, and list discovered devices as they are
published, each with its name, host and, when known, model.

#### Scenario: Devices appear while scanning

- **WHEN** the user opens the add-server screen and discovery confirms `truenas-2.local`
- **THEN** the Nearby section lists `truenas-2.local` while a scanning indicator shows that the scan is still running

#### Scenario: Nothing found

- **WHEN** the scan finishes without confirming any device
- **THEN** the Nearby section says that no devices were found, and the form stays usable

#### Scenario: Scan unavailable

- **WHEN** discovery reports that local network access is unavailable
- **THEN** the Nearby section explains that local network access is needed to find devices, and the form stays usable

### Requirement: Choosing a TrueNAS device fills in the form

Selecting a discovered TrueNAS device SHALL fill in the server name, host,
port and HTTPS setting from the device, and SHALL leave the username and
password for the user. Fields the user already typed into SHALL be
overwritten only by this explicit selection.

#### Scenario: Selecting a device (SCALE 25.10)

- **WHEN** the user taps the discovered TrueNAS device `truenas-2.local` reached over HTTPS on port 443
- **THEN** the form shows name `truenas-2`, host `truenas-2.local`, port 443 and HTTPS on, and the username and password fields are unchanged

### Requirement: Synology devices are listed but not selectable

Discovered Synology devices SHALL appear in the Nearby section as disabled
entries labelled "not supported yet", and selecting one SHALL NOT change the
form.

#### Scenario: Synology device shown disabled (DSM 7.4.1)

- **WHEN** discovery confirms the Synology device `harpalyke`
- **THEN** the Nearby section lists `harpalyke` disabled with the label "not supported yet", and tapping it leaves the form unchanged
