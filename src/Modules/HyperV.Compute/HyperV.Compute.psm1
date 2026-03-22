<#
.SYNOPSIS
    Library module for declarative Hyper-V VM Compute management.
.DESCRIPTION
    Implements Docs\Spec\hyperv_compute_spec.md
#>


$publicDir = Join-Path $PSScriptRoot "Public"
if (Test-Path $publicDir) {
    Get-ChildItem -Path $publicDir -Filter "*.ps1" | ForEach-Object { . $_.FullName }
}

Export-ModuleMember -Function Assert-ComputeState
