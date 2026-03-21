# Feature: Hyper-V Network Domain Automation (Feat 002)

## Context / User Story
**As an** automation engineer,
**I want** to declaratively manage Hyper-V Virtual Switches,
**So that** I can ensure the host networking infrastructure is consistently configured before attaching Virtual Machines.

## Functional Requirements (FR)
- The system MUST parse a JSON array of `VirtualSwitches`.
- The system MUST assert the `Present` or `Absent` state of each Virtual Switch.
- The system MUST create a new Virtual Switch if `State` is `Present` and it does not exist.
- The system MUST remove a Virtual Switch if `State` is `Absent` and it exists.
- The system MUST support `Private` or `Internal` switch types, defaulting to `Private`.
- The system MUST log a WARN instead of recreating the switch if there is a drift in `SwitchType` (safety override).

## Non-Functional Requirements (NFR)
- **Idempotency:** Re-running the module with the same JSON payload MUST log DEBUG skip messages if the network state already matches the desired state.
- **Fail-Fast:** Creation or removal errors MUST stop execution (`ErrorAction Stop`).
- **Logging:** All state changes (additions/removals) MUST log as INFO, while skips log as DEBUG.

## Out-of-Scope
- External Virtual Switches bounded to physical network adapters (to prevent connectivity loss on the host during automation).
- VLAN tagging and advanced network adapter port profiles.
- On-the-fly modification of SwitchType (requires recreation, which is excluded for demo safety).

## JSON Schema Details
`VirtualSwitches` Array:
- `Name`: `[string]` (Required) Name of the Switch.
- `State`: `[string]` (Required) `Present` or `Absent`.
- `SwitchType`: `[string]` (Optional) `Private` or `Internal`. Default: `Private`.

## Algorithm / Implementation Logic (`Assert-NetworkState`)
- **Input**: `[object] $SwitchData`
- Attempt `Get-VMSwitch -Name $SwitchData.Name -ErrorAction SilentlyContinue`.
- **If State is 'Absent'**:
  - Exists? `Remove-VMSwitch -Force -ErrorAction Stop`. Log INFO.
  - Doesn't Exist? Log DEBUG skip.
- **If State is 'Present'**:
  - Doesn't Exist? `New-VMSwitch -Name $SwitchData.Name -SwitchType $SwitchData.SwitchType -ErrorAction Stop`. Log INFO.
  - Exists? 
    - Check SwitchType drift.
    - If drifted, Log WARN that modifying SwitchTypes on the fly isn't supported without recreating, and skip (for this demo's safety).
    - If matched, Log DEBUG skip.

## Success Criteria (Acceptance)
- **Given** a `VirtualSwitches` payload defining a `Private` switch named "LAN", **When** it does not exist, **Then** it is created successfully.
- **Given** an existing "LAN" switch, **When** the payload is rerun, **Then** no modifications are made and a DEBUG skip is logged.
- **Given** a `VirtualSwitches` payload marking "LAN" as `Absent`, **When** the script executes, **Then** the switch is forcibly removed.
