<#
.SYNOPSIS
    Library module for centralized logging.
.DESCRIPTION
    Provides Write-Log to generate Developer, Aggregator (JSON), and Console logs.
    Includes log rotation and retention policies as defined in Docs\Spec\logging_spec.md
#>

$script:LogDirectory = Join-Path $PSScriptRoot "..\..\Logs"
$script:DevLogDir = Join-Path $script:LogDirectory "Developer"
$script:AggLogDir = Join-Path $script:LogDirectory "Aggregator"
$script:ArchiveDir = Join-Path $script:LogDirectory "Archive"

$privateDir = Join-Path $PSScriptRoot "Private"
if (Test-Path $privateDir) {
    Get-ChildItem -Path $privateDir -Filter "*.ps1" | ForEach-Object { . $_.FullName }
}

$publicDir = Join-Path $PSScriptRoot "Public"
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter "*.ps1" | ForEach-Object { . $_.FullName }
}

# Run init and rotation on import
Initialize-LoggingInfrastructure
Invoke-LogRotation

Export-ModuleMember -Function Write-Log
