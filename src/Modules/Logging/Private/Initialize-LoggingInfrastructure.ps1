function Initialize-LoggingInfrastructure {
    <#
    .SYNOPSIS
        Initializes the logging directory structure.
    .DESCRIPTION
        Ensures the Developer, Aggregator, and Archive directories exist before logging operations begin. Creates them if they do not exist.
    .EXAMPLE
        Initialize-LoggingInfrastructure
    #>
    [CmdletBinding()]
    param()

    process {
        # Ensure directories exist
        foreach ($dir in @($script:DevLogDir, $script:AggLogDir, $script:ArchiveDir)) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Force -Path $dir | Out-Null
            }
        }
    }
}
