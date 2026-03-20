function Assert-ComputeState {
    <#
    .SYNOPSIS
        Asserts the desired state of a Hyper-V Virtual Machine.
    .DESCRIPTION
        Reads the provided desired state for a Virtual Machine and performs operations (create, update, delete) to enforce the expected configuration, including CPU count, memory startup bytes, network attachment, and storage attachment. Ensuring idempotency by only modifying actual configuration drift.
    .EXAMPLE
        Assert-ComputeState -VMData $vmObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $VMData
    )

    process {
        $vmName = $VMData.Name
        $state = $VMData.State
        $desiredCpu = if ($null -ne $VMData.CPUCount) { [int]$VMData.CPUCount } else { 1 }
        $desiredMemory = if ($null -ne $VMData.MemoryMB) { [int]$VMData.MemoryMB } else { 2048 }
        $switchName = $VMData.SwitchName
        $vhdPath = $VMData.VHDPath

        $ctx = @{ VMName = $vmName; DesiredState = $state }
        Write-Log -Message "Asserting Compute State for $vmName" -Level DEBUG -ContextData $ctx

        try {
            $currentVM = Get-VM -Name $vmName -ErrorAction SilentlyContinue

            if ($state -eq 'Absent') {
                if ($null -ne $currentVM) {
                    Write-Log -Message "VM '$vmName' exists but desired state is Absent. Removing." -Level INFO -ContextData $ctx
                    if ($currentVM.State -eq 'Running') {
                        $stopParams = @{ Name = $vmName; Force = $true; TurnOff = $true; ErrorAction = 'Stop' }
                        Stop-VM @stopParams
                    }
                    $removeParams = @{ Name = $vmName; Force = $true; ErrorAction = 'Stop' }
                    Remove-VM @removeParams
                    Write-Log -Message "DELETED: Virtual Machine '$vmName'." -Level INFO -ContextData $ctx
                } else {
                    Write-Log -Message "VM '$vmName' is already Absent. Skipping." -Level DEBUG -ContextData $ctx
                }
            } 
            elseif ($state -eq 'Present') {
                if ($null -eq $currentVM) {
                    Write-Log -Message "VM '$vmName' does not exist. Creating." -Level INFO -ContextData $ctx
                    $memoryBytes = $desiredMemory * 1MB
                    
                    $newVmParams = @{ Name = $vmName; MemoryStartupBytes = $memoryBytes; ErrorAction = 'Stop' }
                    New-VM @newVmParams | Out-Null

                    $setCpuParams = @{ VMName = $vmName; Count = $desiredCpu; ErrorAction = 'Stop' }
                    Set-VMProcessor @setCpuParams
                    
                    # Network Attachment
                    if (-not [string]::IsNullOrEmpty($switchName)) {
                        Write-Log -Message "Attaching VM to Switch: $switchName" -Level INFO -ContextData $ctx
                        $netParams = @{ VMName = $vmName; SwitchName = $switchName; ErrorAction = 'Stop' }
                        Connect-VMNetworkAdapter @netParams
                    }

                    # Storage Attachment
                    if (-not [string]::IsNullOrEmpty($vhdPath)) {
                        Write-Log -Message "Attaching VHD to VM: $vhdPath" -Level INFO -ContextData $ctx
                        $vhdParams = @{ VMName = $vmName; Path = $vhdPath; ErrorAction = 'Stop' }
                        Add-VMHardDiskDrive @vhdParams
                    }

                    Write-Log -Message "CREATED: Virtual Machine '$vmName'." -Level INFO -ContextData $ctx
                } else {
                    $modified = $false
                    
                    # Check CPU
                    if ($currentVM.ProcessorCount -ne $desiredCpu) {
                        Write-Log -Message "CPU Drift detected. Expected: $desiredCpu, Actual: $($currentVM.ProcessorCount)" -Level DEBUG -ContextData $ctx
                        $wasRunning = ($currentVM.State -eq 'Running')
                        if ($wasRunning) { 
                            $syncStopParams = @{ Name = $vmName; Force = $true; TurnOff = $true; ErrorAction = 'Stop' }
                            Stop-VM @syncStopParams 
                        }
                        
                        Set-VMProcessor -VMName $vmName -Count $desiredCpu -ErrorAction Stop
                        $modified = $true
                        
                        if ($wasRunning) { Start-VM -Name $vmName -ErrorAction Stop }
                        Write-Log -Message "UPDATED: VM '$vmName' CPU count changed to $desiredCpu." -Level INFO -ContextData $ctx
                    }

                    # Check Memory
                    if ($currentVM.MemoryStartup -ne ($desiredMemory * 1MB)) {
                        Write-Log -Message "Memory Drift detected. Expected: $($desiredMemory * 1MB), Actual: $($currentVM.MemoryStartup)" -Level DEBUG -ContextData $ctx
                        $wasRunning = ($currentVM.State -eq 'Running')
                        if ($wasRunning) { 
                            $syncStopParams = @{ Name = $vmName; Force = $true; TurnOff = $true; ErrorAction = 'Stop' }
                            Stop-VM @syncStopParams 
                        }
                        
                        Set-VMMemory -VMName $vmName -StartupBytes ($desiredMemory * 1MB) -ErrorAction Stop
                        $modified = $true
                        
                        if ($wasRunning) { Start-VM -Name $vmName -ErrorAction Stop }
                        Write-Log -Message "UPDATED: VM '$vmName' Memory changed to $desiredMemory MB." -Level INFO -ContextData $ctx
                    }

                    # Drift Check: Networking
                    if (-not [string]::IsNullOrEmpty($switchName)) {
                        $adapters = Get-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue
                        if ($null -eq $adapters -or $adapters.SwitchName -notcontains $switchName) {
                            Write-Log -Message "Network drift detected. Expected attachment to $switchName." -Level INFO -ContextData $ctx
                            $netParams = @{ VMName = $vmName; SwitchName = $switchName; ErrorAction = 'Stop' }
                            Connect-VMNetworkAdapter @netParams
                            $modified = $true
                        }
                    }

                    if (-not $modified) {
                        Write-Log -Message "SKIPPED: VM '$vmName' is already in the desired state." -Level DEBUG -ContextData $ctx
                    }
                }
            } else {
                Write-Log -Message "Unknown Desired State '$state' for VM '$vmName'." -Level ERROR -ContextData $ctx
            }
        } catch {
            Write-Log -Message "A terminating error occurred asserting state for $vmName. Details: $_" -Level ERROR -ContextData $ctx
            throw
        }
    }
}
