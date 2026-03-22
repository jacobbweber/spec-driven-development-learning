function Assert-NetworkState {
    <#
    .SYNOPSIS
        Declaratively enforces the expected configuration state of a Hyper-V Virtual Switch.

    .DESCRIPTION
        Assert-NetworkState evaluates a parsed JSON definition outlining a desired Virtual Switch 
        and compares it against the local infrastructure via `Get-VMSwitch`. Utilizing an idempotent 
        design, it validates Switch presence and Type ('Private', 'Internal', 'External') prior 
        to performing mutative actions.
        
        The function delegates status reporting entirely to the injected `[Context]` object.

    .PARAMETER SwitchData
        A generic object or PSCustomObject representing the switch configuration.
        Expected properties: Name, State (Present/Absent), SwitchType.

    .PARAMETER Context
        A mandatory [Context] object to supply the thread-safe Logger and Telemetry capabilities. (Using [object] for testing cross-scope limits).

    .EXAMPLE
        # Example 1: Defining a standard Private internal switch for isolated communications
        $switchDefinition = [PSCustomObject]@{
            Name       = "Demo-Private-Switch"
            State      = "Present"
            SwitchType = "Private"
        }
        $context = [Context]::new("C:\Logs")
        Assert-NetworkState -SwitchData $switchDefinition -Context $context

    .EXAMPLE
        # Example 2: Declaring switch removal
        $switchDefinition = @{ Name = "Old-Test-Switch"; State = "Absent" }
        Assert-NetworkState -SwitchData $switchDefinition -Context $context
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $SwitchData,

        [Parameter(Mandatory = $true)]
        [object] $Context
    )

    process {
        $name = $SwitchData.Name
        $state = $SwitchData.State
        $type = if ($null -ne $SwitchData.SwitchType) { $SwitchData.SwitchType } else { 'Private' }

        $ctx = @{ SwitchName = $name; DesiredState = $state }
        $Context.Logger.Write("Asserting Network State for $name", "DEBUG", "Assert-NetworkState", $ctx)

        try {
            $currentSwitch = Get-VMSwitch -Name $name -ErrorAction SilentlyContinue

            if ($state -eq 'Absent') {
                if ($null -ne $currentSwitch) {
                    $Context.Logger.Write("Switch '$name' exists but desired state is Absent. Removing.", "INFO", "Assert-NetworkState", $ctx)
                    $removeParams = @{
                        Name = $name
                        Force = $true
                        ErrorAction = 'Stop'
                    }
                    Remove-VMSwitch @removeParams
                    $Context.Logger.Write("DELETED: Virtual Switch '$name'.", "INFO", "Assert-NetworkState", $ctx)
                    $Context.Telemetry.TrackEvent("Network", "Deleted", $ctx)
                } else {
                    $Context.Logger.Write("Switch '$name' is already Absent. Skipping.", "DEBUG", "Assert-NetworkState", $ctx)
                }
            } elseif ($state -eq 'Present') {
                if ($null -eq $currentSwitch) {
                    $Context.Logger.Write("Switch '$name' does not exist. Creating.", "INFO", "Assert-NetworkState", $ctx)
                    $newParams = @{
                        Name = $name
                        SwitchType = $type
                        ErrorAction = 'Stop'
                    }
                    New-VMSwitch @newParams | Out-Null
                    $Context.Logger.Write("CREATED: Virtual Switch '$name' of type $type.", "INFO", "Assert-NetworkState", $ctx)
                    $Context.Telemetry.TrackEvent("Network", "Created", $ctx)
                } else {
                    if ($currentSwitch.SwitchType -ne $type) {
                        $Context.Logger.Write("SwitchType drift detected for '$name'. Expected: $type, Actual: $($currentSwitch.SwitchType). Modification requires recreation. Skipping for demo safety.", "WARN", "Assert-NetworkState", $ctx)
                        $Context.Telemetry.TrackEvent("Network", "DriftDetected", $ctx)
                    } else {
                        $Context.Logger.Write("SKIPPED: Switch '$name' is already in desired state.", "DEBUG", "Assert-NetworkState", $ctx)
                    }
                }
            } else {
                $Context.Logger.Write("Unknown Desired State '$state' for Switch '$name'.", "ERROR", "Assert-NetworkState", $ctx)
                $Context.Telemetry.TrackEvent("Network", "Error", @{ Reason = "UnknownState"; Name = $name })
            }
        } catch {
            $Context.Logger.Write("A terminating error occurred asserting network state for $name. Details: $_", "ERROR", "Assert-NetworkState", $ctx)
            $Context.Telemetry.TrackEvent("Network", "Error", @{ Error = $_.Exception.Message; Name = $name })
            throw
        }
    }
}
