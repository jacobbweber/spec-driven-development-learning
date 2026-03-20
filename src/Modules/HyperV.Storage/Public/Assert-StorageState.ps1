function Assert-StorageState {
    <#
    .SYNOPSIS
        Asserts the desired state of a Hyper-V Virtual Hard Disk.
    .DESCRIPTION
        Reads the provided desired state for a Virtual Hard Disk and creates, expands, or removes the VHDX to enforce the expected configuration based on path and size bytes. Ensures idempotency by checking bounds before modifying.
    .EXAMPLE
        Assert-StorageState -StorageData $diskObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $StorageData
    )

    process {
        $path = $StorageData.Path
        $state = $StorageData.State
        # Default ~10GB
        $sizeBytes = if ($null -ne $StorageData.SizeBytes) { [long]$StorageData.SizeBytes } else { 10737418240 }

        $ctx = @{ VHDPath = $path; DesiredState = $state }
        Write-Log -Message "Asserting Storage State for $path" -Level DEBUG -ContextData $ctx

        try {
            $currentVhd = Get-VHD -Path $path -ErrorAction SilentlyContinue

            if ($state -eq 'Absent') {
                if ($null -ne $currentVhd -or (Test-Path $path)) {
                    Write-Log -Message "VHDX '$path' exists but desired state is Absent. Removing." -Level INFO -ContextData $ctx
                    Remove-Item -Path $path -Force -ErrorAction Stop
                    Write-Log -Message "DELETED: Virtual Hard Disk '$path'." -Level INFO -ContextData $ctx
                } else {
                    Write-Log -Message "VHDX '$path' is already Absent. Skipping." -Level DEBUG -ContextData $ctx
                }
            } elseif ($state -eq 'Present') {
                if ($null -eq $currentVhd) {
                    Write-Log -Message "VHDX '$path' does not exist. Creating." -Level INFO -ContextData $ctx
                    $parentDir = Split-Path $path -Parent
                    if (-not (Test-Path $parentDir)) { New-Item -ItemType Directory -Force -Path $parentDir | Out-Null }
                    
                    $newParams = @{
                        Path = $path
                        SizeBytes = $sizeBytes
                        Dynamic = $true
                        ErrorAction = 'Stop'
                    }
                    New-VHD @newParams | Out-Null
                    Write-Log -Message "CREATED: Virtual Hard Disk '$path' ($sizeBytes Bytes)." -Level INFO -ContextData $ctx
                } else {
                    if ($currentVhd.Size -lt $sizeBytes) {
                        Write-Log -Message "Disk '$path' is smaller than desired state. Expanding." -Level INFO -ContextData $ctx
                        $resizeParams = @{
                            Path = $path
                            SizeBytes = $sizeBytes
                            ErrorAction = 'Stop'
                        }
                        Resize-VHD @resizeParams
                        Write-Log -Message "UPDATED: Virtual Hard Disk '$path' expanded to $sizeBytes Bytes." -Level INFO -ContextData $ctx
                    } elseif ($currentVhd.Size -gt $sizeBytes) {
                        Write-Log -Message "Disk '$path' is larger than desired state. Shrink not natively supported in this declarative context. Skipping." -Level WARN -ContextData $ctx
                    } else {
                        Write-Log -Message "SKIPPED: Disk '$path' is already in desired state." -Level DEBUG -ContextData $ctx
                    }
                }
            } else {
                Write-Log -Message "Unknown Desired State '$state' for Disk '$path'." -Level ERROR -ContextData $ctx
            }
        } catch {
            Write-Log -Message "A terminating error occurred asserting storage state for $path. Details: $_" -Level ERROR -ContextData $ctx
            throw
        }
    }
}
