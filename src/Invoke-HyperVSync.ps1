<#
.SYNOPSIS
    Controller script to synchronize all Hyper-V resources against a desired state JSON file.

.DESCRIPTION
    Reads a state.json file and orchestrates Network, Storage, and Compute domains
    in the proper architectural sequence.

.PARAMETER StateFilePath
    Absolute or relative path to the desired state JSON file.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $StateFilePath
)

# 1. Initialization and validation
$ErrorActionPreference = 'Stop' # Fail-Fast Enforcement

try {
    $absolutePath = Resolve-Path -Path $StateFilePath -ErrorAction Stop | Select-Object -ExpandProperty Path
} catch {
    throw "State file not found at: $StateFilePath"
}

if (-not (Test-Path $absolutePath)) {
    throw "State file not found at: $absolutePath"
}

# 2. Import dependencies
$loggingModulePath = Join-Path -Path $PSScriptRoot -ChildPath "Modules\Logging\Logging.psm1"
Import-Module -Name $loggingModulePath -Force

Import-Module -Name (Join-Path $PSScriptRoot "Modules\HyperV.Network\HyperV.Network.psm1") -Force
Import-Module -Name (Join-Path $PSScriptRoot "Modules\HyperV.Storage\HyperV.Storage.psm1") -Force
Import-Module -Name (Join-Path $PSScriptRoot "Modules\HyperV.Compute\HyperV.Compute.psm1") -Force

# 3. Load Desired State Payload
try {
    $rawJson = Get-Content -Path $absolutePath -Raw
    $desiredStateData = $rawJson | ConvertFrom-Json
} catch {
    Write-Log -Message "Failed to parse JSON state file: $_" -Level ERROR
    throw
}

# 4. Invoke library functions
Write-Log -Message "Starting Hyper-V Declarative Sync Process" -Level INFO

# Domain 1: Networking (Compute VMs need Switches to exist)
if ($null -ne $desiredStateData.VirtualSwitches) {
    Write-Log -Message "Orchestrating Network Domain" -Level INFO
    foreach ($switch in $desiredStateData.VirtualSwitches) {
        try { Assert-NetworkState -SwitchData $switch }
        catch { throw }
    }
}

# Domain 2: Storage (Compute VMs need VHDXs to exist)
if ($null -ne $desiredStateData.VirtualHardDisks) {
    Write-Log -Message "Orchestrating Storage Domain" -Level INFO
    foreach ($disk in $desiredStateData.VirtualHardDisks) {
        try { Assert-StorageState -StorageData $disk }
        catch { throw }
    }
}

# Domain 3: Compute (Depends on Network & Storage)
if ($null -ne $desiredStateData.VirtualMachines) {
    Write-Log -Message "Orchestrating Compute Domain" -Level INFO
    foreach ($vm in $desiredStateData.VirtualMachines) {
        try { Assert-ComputeState -VMData $vm }
        catch { throw }
    }
}

Write-Log -Message "Hyper-V Declarative Sync Completed" -Level INFO
