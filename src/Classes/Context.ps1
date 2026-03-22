# Requires -Version 7.0

<#
.SYNOPSIS
    Centralized Controller Context Object.

.DESCRIPTION
    Replaces traditional heavy cross-module variable passing. The Context object represents the 
    core "Source of Truth" during script orchestration. It centrally initializes and holds 
    the active Logger class, Telemetry collector, overarching Session configurations, and 
    the active execution semantic $Mode (e.g., Audit or Remediate).

    The Context object is the ONLY variable needed to be passed deeply through Library modules,
    ensuring a Service-Oriented architecture paradigm where libraries grab their services directly 
    off the Context reference.

.EXAMPLE
    # Example 1: Instantiating and utilizing the Context Object
    $context = [Context]::new("C:\TempLogs")
    
    # Passing context down to module functions
    Assert-ComputeState -VMData $vmData -Context $context

.EXAMPLE
    # Example 2: Configuring context switches dynamically
    $context = [Context]::new("C:\TempLogs")
    $context.Mode = "Audit" # Switch to Audit mode
    $context.Configuration['StrictChecks'] = $true
#>
class Context {
    [string]$Mode
    [Logger]$Logger
    [Telemetry]$Telemetry
    [hashtable]$Configuration

    <#
    .SYNOPSIS
        Constructor for the top-level Context object.
    .DESCRIPTION
        Automatically fires up instances for the nested Object dependencies such 
        as Logger and Telemetry to ensure they are available for consumer requests 
        immediately.
    #>
    Context([string]$LogDir) {
        $this.Mode = 'Remediate' # Default operation mode
        $this.Logger = [Logger]::new($LogDir)
        $this.Telemetry = [Telemetry]::new()
        $this.Configuration = @{}
    }
}
