function Assert-StorageState {
    <#
    .SYNOPSIS
        Declaratively enforces the expected configuration state of a Hyper-V Virtual Hard Disk.

    .DESCRIPTION
        Assert-StorageState assesses the intended dimensions and filepath of a VHDX file against the host. 
        It supports stateful checks including dynamic instantiation (`New-VHD`), programmatic disk expansion 
        (`Resize-VHD`) if the desired size outpaces the actual size, or targeted removals if the requested 
        State equals 'Absent'.
        
        Relies deeply on the `[Context]` provider for atomic logging traces and workflow metrics.

    .PARAMETER StorageData
        A custom object mapping to the VHD configuration. 
        Expected properties: Path (Absolute URI to .vhdx), State (Present/Absent), SizeBytes (long).

    .PARAMETER Context
        A [Context] instance ensuring logging isolation across runspaces. (Typed as [object] to prevent cross-scope cast exceptions).

    .EXAMPLE
        # Example 1: Ensuring base disk allocation at 20GB
        $diskDef = [PSCustomObject]@{
            Path      = "D:\Hyper-V\Disks\Server-01.vhdx"
            State     = "Present"
            SizeBytes = 21474836480  # 20 GB
        }
        $ctx = [Context]::new("C:\Logs")
        Assert-StorageState -StorageData $diskDef -Context $ctx

    .EXAMPLE
        # Example 2: Removing obsolete disks dynamically mapped
        $diskDef = @{ Path = "D:\Hyper-V\Disks\Legacy-01.vhdx"; State = "Absent" }
        Assert-StorageState -StorageData $diskDef -Context $ctx
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $StorageData,

        [Parameter(Mandatory = $true)]
        [object] $Context
    )

    process {
        $path = $StorageData.Path
        $state = $StorageData.State
        # Default ~10GB
        $sizeBytes = if ($null -ne $StorageData.SizeBytes) { [long]$StorageData.SizeBytes } else { 10737418240 }

        $ctx = @{ VHDPath = $path; DesiredState = $state }
        $Context.Logger.Write("Asserting Storage State for $path", "DEBUG", "Assert-StorageState", $ctx)

        try {
            $currentVhd = Get-VHD -Path $path -ErrorAction SilentlyContinue

            if ($state -eq 'Absent') {
                if ($null -ne $currentVhd -or (Test-Path $path)) {
                    $Context.Logger.Write("VHDX '$path' exists but desired state is Absent. Removing.", "INFO", "Assert-StorageState", $ctx)
                    Remove-Item -Path $path -Force -ErrorAction Stop
                    $Context.Logger.Write("DELETED: Virtual Hard Disk '$path'.", "INFO", "Assert-StorageState", $ctx)
                    $Context.Telemetry.TrackEvent("Storage", "Deleted", $ctx)
                } else {
                    $Context.Logger.Write("VHDX '$path' is already Absent. Skipping.", "DEBUG", "Assert-StorageState", $ctx)
                }
            } elseif ($state -eq 'Present') {
                if ($null -eq $currentVhd) {
                    $Context.Logger.Write("VHDX '$path' does not exist. Creating.", "INFO", "Assert-StorageState", $ctx)
                    $parentDir = Split-Path $path -Parent
                    if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Force -Path $parentDir | Out-Null }
                    
                    $newParams = @{
                        Path = $path
                        SizeBytes = $sizeBytes
                        Dynamic = $true
                        ErrorAction = 'Stop'
                    }
                    New-VHD @newParams | Out-Null
                    $Context.Logger.Write("CREATED: Virtual Hard Disk '$path' ($sizeBytes Bytes).", "INFO", "Assert-StorageState", $ctx)
                    $Context.Telemetry.TrackEvent("Storage", "Created", $ctx)
                } else {
                    if ($currentVhd.Size -lt $sizeBytes) {
                        $Context.Logger.Write("Disk '$path' is smaller than desired state. Expanding.", "INFO", "Assert-StorageState", $ctx)
                        $resizeParams = @{
                            Path = $path
                            SizeBytes = $sizeBytes
                            ErrorAction = 'Stop'
                        }
                        Resize-VHD @resizeParams
                        $Context.Logger.Write("UPDATED: Virtual Hard Disk '$path' expanded to $sizeBytes Bytes.", "INFO", "Assert-StorageState", $ctx)
                        $Context.Telemetry.TrackEvent("Storage", "Expanded", $ctx)
                    } elseif ($currentVhd.Size -gt $sizeBytes) {
                        $Context.Logger.Write("Disk '$path' is larger than desired state. Shrink not natively supported in this declarative context. Skipping.", "WARN", "Assert-StorageState", $ctx)
                    } else {
                        $Context.Logger.Write("SKIPPED: Disk '$path' is already in desired state.", "DEBUG", "Assert-StorageState", $ctx)
                    }
                }
            } else {
                $Context.Logger.Write("Unknown Desired State '$state' for Disk '$path'.", "ERROR", "Assert-StorageState", $ctx)
                $Context.Telemetry.TrackEvent("Storage", "Error", @{ Reason = "UnknownState"; Path = $path })
            }
        } catch {
            $Context.Logger.Write("A terminating error occurred asserting storage state for $path. Details: $_", "ERROR", "Assert-StorageState", $ctx)
            $Context.Telemetry.TrackEvent("Storage", "Error", @{ Error = $_.Exception.Message; Path = $path })
            throw
        }
    }
}
