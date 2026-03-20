# Hyper-V Storage Domain Specification

## 1. Abstract
The `HyperV.Storage` module provides declarative idempotency for Virtual Hard Disks (VHDX).

## 2. JSON Schema (`VirtualHardDisks` Array)
- `Path`: `[string]` (Required) Absolute path to the VHDX file.
- `State`: `[string]` (Required) `Present` or `Absent`.
- `SizeBytes`: `[long]` (Optional) Desired size of the disk in bytes. Default: 10GB (10737418240).

## 3. Algorithm: `Assert-StorageState`
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
