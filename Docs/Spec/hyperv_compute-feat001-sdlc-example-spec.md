# Feature: Hyper-V Compute Domain Automation (Feat 001)

## Context / User Story
**As an** automation engineer,
**I want** to declaratively assert the state of Hyper-V Virtual Machines (Compute),
**So that** I can ensure VMs are provisioned, configured with correct CPU/RAM, and attached to required networks and storage without manual intervention.

## Functional Requirements (FR)
- The system MUST parse a JSON array of `VirtualMachines`.
- The system MUST assert the `Present` or `Absent` state of each VM.
- The system MUST create a new VM if `State` is `Present` and it does not exist.
- The system MUST remove a VM if `State` is `Absent` and it exists (stopping it first if running).
- The system MUST configure the VM's `CPUCount` and `MemoryMB` if explicitly provided, or use defaults (1 Core, 2048 MB).
- The system MUST connect the VM to a Virtual Switch if `SwitchName` is provided.
- The system MUST attach a VHDX to the VM if `VHDPath` is provided.
- The system MUST assess and remediate configuration drift for CPU, Memory, and Network Switch if the VM already exists.

## Non-Functional Requirements (NFR)
- **Idempotency:** Re-running the module with the same JSON payload MUST NOT cause changes or errors if the desired state is already met.
- **Fail-Fast:** Errors during assertion MUST stop execution (`ErrorAction Stop`).
- **Performance:** State comparisons MUST happen prior to issuing update commands to minimize Hyper-V host impact.

## Out-of-Scope
- Complex dynamic disk hot-swapping (only warn if VHDPath is missing from an existing VM).
- Managing Guest OS internal configuration (e.g., IP addressing inside the VM).
- Live Migration or Cluster Shared Volume (CSV) placement management.

## JSON Schema Details
`VirtualMachines` Array:
- `Name`: `[string]` (Required) VM Name.
- `State`: `[string]` (Required) `Present` or `Absent`.
- `CPUCount`: `[int]` (Optional) Number of vCPUs. Default: 1.
- `MemoryMB`: `[int]` (Optional) RAM. Default: 2048.
- `SwitchName`: `[string]` (Optional) Name of a Virtual Switch to attach.
- `VHDPath`: `[string]` (Optional) Absolute path to a VHDX to attach.

## Algorithm / Implementation Logic (`Assert-ComputeState`)
- **Input**: `[object] $VMData`
- Standard idempotent wrapper `try/catch`. ErrorAction Stop. `Get-VM` to check existence.
- **If Absent**: Stop VM (if running), Remove VM.
- **If Present**:
  - **Does not exist**:
    - `New-VM` (No VHD attached yet).
    - `Set-VMProcessor` for CPU.
    - Check if `$VMData.SwitchName` is provided. If so, `Connect-VMNetworkAdapter -VMName ... -SwitchName $VMData.SwitchName`.
    - Check if `$VMData.VHDPath` is provided. If so, `Add-VMHardDiskDrive -VMName ... -Path $VMData.VHDPath`.
  - **Exists**:
    - Check CPU and Memory drift. Update if necessary (requires VM stop).
    - *Network Check*: `Get-VMNetworkAdapter`. If `SwitchName` differs, `Connect-VMNetworkAdapter` to new switch.
    - *Storage Check*: `Get-VMHardDiskDrive`. If `$VMData.VHDPath` is not in the list, warn.

## Success Criteria (Acceptance)
- **Given** a `VirtualMachines` payload where a VM should be `Present`, **When** the script executes and the VM does not exist, **Then** a new VM is created with the specified hardware constraints.
- **Given** an existing VM with 2 vCPUs, **When** the payload specifies 4 vCPUs, **Then** the VM is stopped (if required), processor count updated, and desired state achieved.
- **Given** a VM intended to be `Absent`, **When** the script executes, **Then** the VM is verified deleted from the Hyper-V host.
