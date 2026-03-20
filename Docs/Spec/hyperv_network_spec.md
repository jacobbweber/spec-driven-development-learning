# Hyper-V Network Domain Specification

## 1. Abstract
The `HyperV.Network` module provides declarative idempotency for Virtual Switches.

## 2. JSON Schema (`VirtualSwitches` Array)
- `Name`: `[string]` (Required) Name of the Switch.
- `State`: `[string]` (Required) `Present` or `Absent`.
- `SwitchType`: `[string]` (Optional) `Private` or `Internal`. Default: `Private`.

## 3. Algorithm: `Assert-NetworkState`
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
