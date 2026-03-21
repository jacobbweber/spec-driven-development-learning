# Feature: Hyper-V Storage Domain Automation (Feat 003)

## Context / User Story
**As an** automation engineer,
**I want** to declaratively manage Virtual Hard Disks (VHDX),
**So that** I can automatically provision, expand, or remove underlying VM storage using a JSON configuration.

## Functional Requirements (FR)
- The system MUST parse a JSON array of `VirtualHardDisks`.
- The system MUST assert the `Present` or `Absent` state of each VHDX file.
- The system MUST create a dynamically expanding VHDX if `State` is `Present` and the file does not exist.
- The system MUST delete the specified VHDX file if `State` is `Absent` and it exists.
- The system MUST evaluate the existing size of the VHDX file against the desired `SizeBytes`.
- The system MUST automatically expand the VHDX if the existing size is less than `SizeBytes`.
- The system MUST NOT shrink the VHDX if the existing size is greater than `SizeBytes`, but rather log a WARN.

## Non-Functional Requirements (NFR)
- **Idempotency:** Re-running the module with the same JSON payload MUST NOT alter existing VHDX files if they meet the desired size criteria.
- **Fail-Fast:** Creation, expansion, or removal errors MUST stop execution (`ErrorAction Stop`).
- **Disk Format:** All newly provisioned disks MUST default to Dynamically Expanding VHDX.

## Out-of-Scope
- Declarative shrinking of Virtual Hard Disks (unsupported operation safely).
- Conversion between Fixed, Dynamic, and Differencing disk types.
- Storage Spaces inside the guest OS or host-level clustered storage configurations.

## JSON Schema Details
`VirtualHardDisks` Array:
- `Path`: `[string]` (Required) Absolute path to the VHDX file.
- `State`: `[string]` (Required) `Present` or `Absent`.
- `SizeBytes`: `[long]` (Optional) Desired size of the disk in bytes. Default: 10GB (10737418240).

## Algorithm / Implementation Logic (`Assert-StorageState`)
- **Input**: `[object] $StorageData`
- Attempt `Get-VHD -Path $StorageData.Path -ErrorAction SilentlyContinue`.
- **If State is 'Absent'**:
  - Exists? `Remove-Item -Path $StorageData.Path -Force -ErrorAction Stop`. Log INFO.
  - Doesn't Exist? Log DEBUG skip.
- **If State is 'Present'**:
  - Doesn't Exist? `New-VHD -Path $StorageData.Path -SizeBytes $StorageData.SizeBytes -Dynamic -ErrorAction Stop`. Log INFO.
  - Exists? 
    - Check `$currentVHD.Size` against `$StorageData.SizeBytes`.
    - If `$currentVHD.Size -lt $StorageData.SizeBytes`, expand it: `Resize-VHD -Path $StorageData.Path -SizeBytes $StorageData.SizeBytes -ErrorAction Stop`. Log INFO.
    - If `$currentVHD.Size -gt $StorageData.SizeBytes`, shrinking is unsupported declaratively here. Log WARN.
    - If matched, Log DEBUG skip.

## Success Criteria (Acceptance)
- **Given** a `VirtualHardDisks` payload defining a 10GB VHDX, **When** the file does not exist, **Then** a new dynamic VHDX is created at the specified path.
- **Given** an existing 10GB VHDX, **When** the payload is updated to request 20GB, **Then** the VHDX is safely expanded to 20GB.
- **Given** a `VirtualHardDisks` payload mapping a VHDX to `Absent`, **When** the script executes, **Then** the file is deleted from the filesystem.
