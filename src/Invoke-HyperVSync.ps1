<#
.SYNOPSIS
    Declarative Controller script orchestrating the synchronization of Hyper-V resources.

.DESCRIPTION
    Reads a JSON-formatted desired state payload and orchestrates the deployment map across 
    Network, Storage, and Compute domains in the correct architectural sequence. 
    It acts as the primary orchestrator, initializing the Service-Oriented `[Context]` object 
    (with Logger and Telemetry providers), and passing it to the foundational Library modules.

    The execution order is strictly enforced:
    1. Virtual Switches (Networking)
    2. Virtual Hard Disks (Storage)
    3. Virtual Machines (Compute)

.PARAMETER StateFilePath
    Absolute or relative path to the desired state JSON file. Ensure the execution environment 
    has read access to this path.

.EXAMPLE
    # Example 1: Basic synchronization 
    .\Invoke-HyperVSync.ps1 -StateFilePath "C:\Configs\prod-state.json"

.EXAMPLE
    # Example 2: Run and review telemetry output
    .\Invoke-HyperVSync.ps1 -StateFilePath "..\Example\state.json"
    Get-Content "..\Logs\Telemetry\telemetry_*.json"
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
$classesDir = Join-Path $PSScriptRoot "Classes"
if (-not ("Logger" -as [type])) { . (Join-Path $classesDir "Logger.ps1") }
if (-not ("Telemetry" -as [type])) { . (Join-Path $classesDir "Telemetry.ps1") }
if (-not ("Context" -as [type])) { . (Join-Path $classesDir "Context.ps1") }

# Import domain modules, utilizing -Force to flush development caches unless 
# actively executing inside a Pester test suite, which would break active Mock bindings.
$isPester = [bool]((Get-PSCallStack).Command -match 'Invoke-Pester|Describe|It|BeforeAll')
$netModule = Join-Path $PSScriptRoot "Modules\HyperV.Network\HyperV.Network.psm1"
$storageModule = Join-Path $PSScriptRoot "Modules\HyperV.Storage\HyperV.Storage.psm1"
$computeModule = Join-Path $PSScriptRoot "Modules\HyperV.Compute\HyperV.Compute.psm1"

if ($isPester) {
    Import-Module -Name $netModule
    Import-Module -Name $storageModule
    Import-Module -Name $computeModule
} else {
    Import-Module -Name $netModule -Force
    Import-Module -Name $storageModule -Force
    Import-Module -Name $computeModule -Force
}

# Initialize Context
$logDir = Join-Path $PSScriptRoot "..\Logs"
$context = [Context]::new($logDir)

# 3. Load Desired State Payload
try {
    $rawJson = Get-Content -Path $absolutePath -Raw
    $desiredStateData = $rawJson | ConvertFrom-Json
} catch {
    $context.Logger.Write("Failed to parse JSON state file: $_", "ERROR", "Invoke-HyperVSync")
    throw
}

# 4. Invoke library functions
$context.Logger.Write("Starting Hyper-V Declarative Sync Process", "INFO", "Invoke-HyperVSync")

# Domain 1: Networking (Compute VMs need Switches to exist)
if ($null -ne $desiredStateData.VirtualSwitches) {
    $context.Logger.Write("Orchestrating Network Domain", "INFO", "Invoke-HyperVSync")
    foreach ($switch in $desiredStateData.VirtualSwitches) {
        try { Assert-NetworkState -SwitchData $switch -Context $context }
        catch { throw }
    }
}

# Domain 2: Storage (Compute VMs need VHDXs to exist)
if ($null -ne $desiredStateData.VirtualHardDisks) {
    $context.Logger.Write("Orchestrating Storage Domain", "INFO", "Invoke-HyperVSync")
    foreach ($disk in $desiredStateData.VirtualHardDisks) {
        try { Assert-StorageState -StorageData $disk -Context $context }
        catch { throw }
    }
}

# Domain 3: Compute (Depends on Network & Storage)
if ($null -ne $desiredStateData.VirtualMachines) {
    $context.Logger.Write("Orchestrating Compute Domain", "INFO", "Invoke-HyperVSync")
    foreach ($vm in $desiredStateData.VirtualMachines) {
        try { Assert-ComputeState -VMData $vm -Context $context }
        catch { throw }
    }
}

# Export Telemetry
$telemetryDir = Join-Path $logDir "Telemetry"
if (-not (Test-Path $telemetryDir)) { New-Item -ItemType Directory -Force -Path $telemetryDir | Out-Null }
$telemetryPath = Join-Path $telemetryDir "telemetry_$(Get-Date -Format 'yyyyMMdd').json"
$context.Telemetry.Export($telemetryPath)

$context.Logger.Write("Hyper-V Declarative Sync Completed", "INFO", "Invoke-HyperVSync")
