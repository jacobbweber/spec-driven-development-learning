<#
.SYNOPSIS
    Library module for declarative Hyper-V Virtual Switch management.
.DESCRIPTION
    Implements Docs\Spec\hyperv_network_spec.md
#>


$publicDir = Join-Path $PSScriptRoot "Public"
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter "*.ps1" | ForEach-Object { . $_.FullName }
}

Export-ModuleMember -Function Assert-NetworkState
