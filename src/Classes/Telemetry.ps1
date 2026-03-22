<#
.SYNOPSIS
    Thread-safe Telemetry Metrics Collector Class.

.DESCRIPTION
    The Telemetry class abstracts metric collection away from the core business logic. 
    It stores real-time event occurrences utilizing [ConcurrentBag] to ensure that 
    various threads and parallel processes do not experience race conditions or data loss 
    while adding new telemetry events. Events are grouped by category and action type, 
    and ultimately exported collectively at the script boundaries.

.EXAMPLE
    # Example 1: Instantiation and Adding Tracking Data
    $telemetry = [Telemetry]::new()
    
    # Adding metadata regarding an accomplished task
    $telemetry.TrackEvent("Storage", "DiskExpanded", @{ VM="SQL-02"; Size="200GB" })

.EXAMPLE
    # Example 2: Tracking Generic Workflow Events
    $telemetry.TrackEvent("Pipeline", "Started", $null)

.EXAMPLE
    # Example 3: Bulk Export
    $telemetry.Export("C:\Logs\Telemetry\out.json")
#>
class Telemetry {
    [System.Collections.Concurrent.ConcurrentBag[hashtable]]$Events

    <#
    .SYNOPSIS
        Constructor for the Telemetry class.
    .DESCRIPTION
        Instantiates the underlying ConcurrentBag to ensure thread-bound safety.
    #>
    Telemetry() {
        $this.Events = [System.Collections.Concurrent.ConcurrentBag[hashtable]]::new()
    }

    <#
    .SYNOPSIS
        Appends a new event into the thread-safe telemetry context.
    .DESCRIPTION
        Takes broad groupings (Category and Action) and an optional rich Data metadata hash.
    #>
    [void]TrackEvent([string]$Category, [string]$Action, [hashtable]$Data) {
        $event = [ordered]@{
            Timestamp = (Get-Date).ToString("o")
            Category  = $Category
            Action    = $Action
        }
        if ($null -ne $Data) {
            foreach ($key in $Data.Keys) {
                $event[$key] = $Data[$key]
            }
        }
        $this.Events.Add($event)
    }

    <#
    .SYNOPSIS
        Serializes and dumps the tracked telemetry events structure to a physical JSON file.
    .DESCRIPTION
        Converts the finalized Array back from the ConcurrentBag and writes out.
    #>
    [void]Export([string]$FilePath) {
        $data = $this.Events.ToArray()
        if ($data.Count -gt 0) {
            $data | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath -Encoding UTF8
        }
    }
}
