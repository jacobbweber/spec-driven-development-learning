function Assert-ComputeState {
    <#
    .SYNOPSIS
        Declaratively enforces the expected configuration state of a Hyper-V Virtual Machine.

    .DESCRIPTION
        Assert-ComputeState processes a parsed JSON definition object representing a Virtual Machine 
        and compares it against the real-world Hyper-V environment. It utilizes an Idempotent execution 
        strategy—verifying the existing component properties (Presence, CPU, Memory, Switch, and VHD) 
        and executing exact modification functions (`New-VM`, `Set-VMMemory`, etc.) only when drift is 
        identified.
        
        This module fully hooks into the `[Context]` provider architecture for logging and telemetry.

    .PARAMETER VMData
        A generic object or PSCustomObject containing the parsed JSON node representing the VM configuration.
        Expected properties: Name, State (Present/Absent), CPUCount, MemoryMB, SwitchName, VHDPath.

    .PARAMETER Context
        A strongly typed [Context] object bridging the Logger and Telemetry providers for safe thread-execution 
        feedback loops. (Typed as [object] to bypass PowerShell class scope limitations during integration testing).

    .EXAMPLE
        # Example 1: Defining and building a simple VM
        $vmDefinition = [PSCustomObject]@{
            Name     = "Web-Server-01"
            State    = "Present"
            CPUCount = 4
            MemoryMB = 8192
        }
        $context = [Context]::new("C:\Logs")
        Assert-ComputeState -VMData $vmDefinition -Context $context

    .EXAMPLE
        # Example 2: Idempotent removal
        # The following definition ensures the VM is deleted entirely if it exists.
        $vmDefinition = [PSCustomObject]@{
            Name  = "Legacy-App-Server"
            State = "Absent"
        }
        Assert-ComputeState -VMData $vmDefinition -Context $context
        
    .EXAMPLE
        # Example 3: Pipeline chaining
        $config.VirtualMachines | ForEach-Object { Assert-ComputeState -VMData $_ -Context $context }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $VMData,

        [Parameter(Mandatory = $true)]
        [object] $Context
    )

    process {
        $vmName = $VMData.Name
        $state = $VMData.State
        $desiredCpu = if ($null -ne $VMData.CPUCount) { [int]$VMData.CPUCount } else { 1 }
        $desiredMemory = if ($null -ne $VMData.MemoryMB) { [int]$VMData.MemoryMB } else { 2048 }
        $switchName = $VMData.SwitchName
        $vhdPath = $VMData.VHDPath

        $ctx = @{ VMName = $vmName; DesiredState = $state }
        $Context.Logger.Write("Asserting Compute State for $vmName", "DEBUG", "Assert-ComputeState", $ctx)

        try {
            $currentVM = Get-VM -Name $vmName -ErrorAction SilentlyContinue

            if ($state -eq 'Absent') {
                if ($null -ne $currentVM) {
                    $Context.Logger.Write("VM '$vmName' exists but desired state is Absent. Removing.", "INFO", "Assert-ComputeState", $ctx)
                    if ($currentVM.State -eq 'Running') {
                        $stopParams = @{ Name = $vmName; Force = $true; TurnOff = $true; ErrorAction = 'Stop' }
                        Stop-VM @stopParams
                    }
                    $removeParams = @{ Name = $vmName; Force = $true; ErrorAction = 'Stop' }
                    Remove-VM @removeParams
                    $Context.Logger.Write("DELETED: Virtual Machine '$vmName'.", "INFO", "Assert-ComputeState", $ctx)
                    $Context.Telemetry.TrackEvent("Compute", "Deleted", $ctx)
                } else {
                    $Context.Logger.Write("VM '$vmName' is already Absent. Skipping.", "DEBUG", "Assert-ComputeState", $ctx)
                }
            } 
            elseif ($state -eq 'Present') {
                if ($null -eq $currentVM) {
                    $Context.Logger.Write("VM '$vmName' does not exist. Creating.", "INFO", "Assert-ComputeState", $ctx)
                    $memoryBytes = $desiredMemory * 1MB
                    
                    $newVmParams = @{ Name = $vmName; MemoryStartupBytes = $memoryBytes; ErrorAction = 'Stop' }
                    New-VM @newVmParams | Out-Null

                    $setCpuParams = @{ VMName = $vmName; Count = $desiredCpu; ErrorAction = 'Stop' }
                    Set-VMProcessor @setCpuParams
                    
                    # Network Attachment
                    if (-not [string]::IsNullOrEmpty($switchName)) {
                        $Context.Logger.Write("Attaching VM to Switch: $switchName", "INFO", "Assert-ComputeState", $ctx)
                        $netParams = @{ VMName = $vmName; SwitchName = $switchName; ErrorAction = 'Stop' }
                        Connect-VMNetworkAdapter @netParams
                    }

                    # Storage Attachment
                    if (-not [string]::IsNullOrEmpty($vhdPath)) {
                        $Context.Logger.Write("Attaching VHD to VM: $vhdPath", "INFO", "Assert-ComputeState", $ctx)
                        $vhdParams = @{ VMName = $vmName; Path = $vhdPath; ErrorAction = 'Stop' }
                        Add-VMHardDiskDrive @vhdParams
                    }

                    $Context.Logger.Write("CREATED: Virtual Machine '$vmName'.", "INFO", "Assert-ComputeState", $ctx)
                    $Context.Telemetry.TrackEvent("Compute", "Created", $ctx)
                } else {
                    $modified = $false
                    
                    # Check CPU
                    if ($currentVM.ProcessorCount -ne $desiredCpu) {
                        $Context.Logger.Write("CPU Drift detected. Expected: $desiredCpu, Actual: $($currentVM.ProcessorCount)", "DEBUG", "Assert-ComputeState", $ctx)
                        $wasRunning = ($currentVM.State -eq 'Running')
                        if ($wasRunning) { 
                            $syncStopParams = @{ Name = $vmName; Force = $true; TurnOff = $true; ErrorAction = 'Stop' }
                            Stop-VM @syncStopParams 
                        }
                        
                        Set-VMProcessor -VMName $vmName -Count $desiredCpu -ErrorAction Stop
                        $modified = $true
                        
                        if ($wasRunning) { Start-VM -Name $vmName -ErrorAction Stop }
                        $Context.Logger.Write("UPDATED: VM '$vmName' CPU count changed to $desiredCpu.", "INFO", "Assert-ComputeState", $ctx)
                        $Context.Telemetry.TrackEvent("Compute", "Updated_CPU", $ctx)
                    }

                    # Check Memory
                    if ($currentVM.MemoryStartup -ne ($desiredMemory * 1MB)) {
                        $Context.Logger.Write("Memory Drift detected. Expected: $($desiredMemory * 1MB), Actual: $($currentVM.MemoryStartup)", "DEBUG", "Assert-ComputeState", $ctx)
                        $wasRunning = ($currentVM.State -eq 'Running')
                        if ($wasRunning) { 
                            $syncStopParams = @{ Name = $vmName; Force = $true; TurnOff = $true; ErrorAction = 'Stop' }
                            Stop-VM @syncStopParams 
                        }
                        
                        Set-VMMemory -VMName $vmName -StartupBytes ($desiredMemory * 1MB) -ErrorAction Stop
                        $modified = $true
                        
                        if ($wasRunning) { Start-VM -Name $vmName -ErrorAction Stop }
                        $Context.Logger.Write("UPDATED: VM '$vmName' Memory changed to $desiredMemory MB.", "INFO", "Assert-ComputeState", $ctx)
                        $Context.Telemetry.TrackEvent("Compute", "Updated_Memory", $ctx)
                    }

                    # Drift Check: Networking
                    if (-not [string]::IsNullOrEmpty($switchName)) {
                        $adapters = Get-VMNetworkAdapter -VMName $vmName -ErrorAction SilentlyContinue
                        if ($null -eq $adapters -or $adapters.SwitchName -notcontains $switchName) {
                            $Context.Logger.Write("Network drift detected. Expected attachment to $switchName.", "INFO", "Assert-ComputeState", $ctx)
                            $netParams = @{ VMName = $vmName; SwitchName = $switchName; ErrorAction = 'Stop' }
                            Connect-VMNetworkAdapter @netParams
                            $modified = $true
                            $Context.Telemetry.TrackEvent("Compute", "Updated_Network", $ctx)
                        }
                    }

                    if (-not $modified) {
                        $Context.Logger.Write("SKIPPED: VM '$vmName' is already in the desired state.", "DEBUG", "Assert-ComputeState", $ctx)
                    }
                }
            } else {
                $Context.Logger.Write("Unknown Desired State '$state' for VM '$vmName'.", "ERROR", "Assert-ComputeState", $ctx)
                $Context.Telemetry.TrackEvent("Compute", "Error", @{ Reason = "UnknownState"; Name = $vmName })
            }
        } catch {
            $Context.Logger.Write("A terminating error occurred asserting state for $vmName. Details: $_", "ERROR", "Assert-ComputeState", $ctx)
            $Context.Telemetry.TrackEvent("Compute", "Error", @{ Error = $_.Exception.Message; Name = $vmName })
            throw
        }
    }
}
