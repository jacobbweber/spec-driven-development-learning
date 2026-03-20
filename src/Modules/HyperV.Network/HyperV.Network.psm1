<#
.SYNOPSIS
    Library module for declarative Hyper-V Virtual Switch management.
.DESCRIPTION
    Implements Docs\Spec\hyperv_network_spec.md
#>

$loggingModulePath = Join-Path $PSScriptRoot "..\Logging\Logging.psm1"
if (Test-Path $loggingModulePath) { Import-Module $loggingModulePath -Force }

$publicDir = Join-Path $PSScriptRoot "Public"
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter "*.ps1" | ForEach-Object { . $_.FullName }
}

Export-ModuleMember -Function Assert-NetworkState
