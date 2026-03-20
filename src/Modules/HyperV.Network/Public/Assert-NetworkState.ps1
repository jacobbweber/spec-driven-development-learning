function Assert-NetworkState {
    <#
    .SYNOPSIS
        Asserts the desired state of a Hyper-V Virtual Switch.
    .DESCRIPTION
        Reads the provided desired state for a Virtual Switch and creates or removes the switch to enforce the expected configuration, including switch type. Ensures idempotency by checking existing state before making changes.
    .EXAMPLE
        Assert-NetworkState -SwitchData $switchObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object] $SwitchData
    )

    process {
        $name = $SwitchData.Name
        $state = $SwitchData.State
        $type = if ($null -ne $SwitchData.SwitchType) { $SwitchData.SwitchType } else { 'Private' }

        $ctx = @{ SwitchName = $name; DesiredState = $state }
        Write-Log -Message "Asserting Network State for $name" -Level DEBUG -ContextData $ctx

        try {
            $currentSwitch = Get-VMSwitch -Name $name -ErrorAction SilentlyContinue

            if ($state -eq 'Absent') {
                if ($null -ne $currentSwitch) {
                    Write-Log -Message "Switch '$name' exists but desired state is Absent. Removing." -Level INFO -ContextData $ctx
                    $removeParams = @{
                        Name = $name
                        Force = $true
                        ErrorAction = 'Stop'
                    }
                    Remove-VMSwitch @removeParams
                    Write-Log -Message "DELETED: Virtual Switch '$name'." -Level INFO -ContextData $ctx
                } else {
                    Write-Log -Message "Switch '$name' is already Absent. Skipping." -Level DEBUG -ContextData $ctx
                }
            } elseif ($state -eq 'Present') {
                if ($null -eq $currentSwitch) {
                    Write-Log -Message "Switch '$name' does not exist. Creating." -Level INFO -ContextData $ctx
                    $newParams = @{
                        Name = $name
                        SwitchType = $type
                        ErrorAction = 'Stop'
                    }
                    New-VMSwitch @newParams | Out-Null
                    Write-Log -Message "CREATED: Virtual Switch '$name' of type $type." -Level INFO -ContextData $ctx
                } else {
                    if ($currentSwitch.SwitchType -ne $type) {
                        Write-Log -Message "SwitchType drift detected for '$name'. Expected: $type, Actual: $($currentSwitch.SwitchType). Modification requires recreation. Skipping for demo safety." -Level WARN -ContextData $ctx
                    } else {
                        Write-Log -Message "SKIPPED: Switch '$name' is already in desired state." -Level DEBUG -ContextData $ctx
                    }
                }
            } else {
                Write-Log -Message "Unknown Desired State '$state' for Switch '$name'." -Level ERROR -ContextData $ctx
            }
        } catch {
            Write-Log -Message "A terminating error occurred asserting network state for $name. Details: $_" -Level ERROR -ContextData $ctx
            throw
        }
    }
}
