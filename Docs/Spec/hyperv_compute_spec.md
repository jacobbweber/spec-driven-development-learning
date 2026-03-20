# Hyper-V Compute Domain Specification

## 1. Abstract
The `HyperV.Compute` module asserts the state of VMs, including attaching networks and storage defined in other domains.

## 2. JSON Schema (`VirtualMachines` Array)
- `Name`: `[string]` (Required) VM Name.
- `State`: `[string]` (Required) `Present` or `Absent`.
- `CPUCount`: `[int]` (Optional) Number of vCPUs. Default: 1.
- `MemoryMB`: `[int]` (Optional) RAM. Default: 2048.
- `SwitchName`: `[string]` (Optional) Name of a Virtual Switch to attach.
- `VHDPath`: `[string]` (Optional) Absolute path to a VHDX to attach.

## 3. Algorithm: `Assert-ComputeState`
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
    - *Storage Check*: `Get-VMHardDiskDrive`. If `$VMData.VHDPath` is not in the list, warn (for demo simplicity, we won't handle complex disk hot-swapping, just warn if missing).
