Describe 'HyperV.Compute Unit Tests' {
    BeforeAll {
        . "$PSScriptRoot\..\..\src\Classes\Logger.ps1"
        . "$PSScriptRoot\..\..\src\Classes\Telemetry.ps1"
        . "$PSScriptRoot\..\..\src\Classes\Context.ps1"
        
        $modulePath = Join-Path $PSScriptRoot "..\..\src\Modules\HyperV.Compute\HyperV.Compute.psm1"
        Import-Module $modulePath -Force
        
        $script:tempLogDir = Join-Path $env:TEMP "PesterLogs_Compute_$(Get-Random)"
        $script:context = [Context]::new($script:tempLogDir)
    }

    AfterAll {
        if (Test-Path $script:tempLogDir) { Remove-Item -Path $script:tempLogDir -Recurse -Force }
    }

    Context 'Assert-ComputeState' {
        It 'Throws an error if VMData is missing' {
            { Assert-ComputeState -VMData $null -Context $script:context } | Should -Throw
        }

        It 'Mocks New-VM when state is Present and VM does not exist' {
            $mockData = [PSCustomObject]@{ Name = 'TestVM'; State = 'Present'; CPUCount = 2; MemoryMB = 1024 }
            
            Mock Get-VM -ModuleName 'HyperV.Compute' -MockWith { return $null }
            Mock New-VM -ModuleName 'HyperV.Compute' -MockWith { return [PSCustomObject]@{ Name = 'TestVM' } }
            Mock Set-VMProcessor -ModuleName 'HyperV.Compute' -MockWith { }

            Assert-ComputeState -VMData $mockData -Context $script:context

            Assert-MockCalled New-VM -ModuleName 'HyperV.Compute' -Times 1 -Exactly
            Assert-MockCalled Set-VMProcessor -ModuleName 'HyperV.Compute' -Times 1 -Exactly
        }
    }
}
