Describe 'HyperV.Compute Unit Tests' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot "..\..\src\Modules\HyperV.Compute\HyperV.Compute.psm1"
        $loggingModulePath = Join-Path $PSScriptRoot "..\..\src\Modules\Logging\Logging.psm1"
        Import-Module $modulePath -Force
        Import-Module $loggingModulePath -Force
    }

    Context 'Assert-ComputeState' {
        It 'Throws an error if VMData is missing' {
            { Assert-ComputeState -VMData $null } | Should -Throw
        }

        It 'Mocks New-VM when state is Present and VM does not exist' {
            $mockData = [PSCustomObject]@{ Name = 'TestVM'; State = 'Present'; CPUCount = 2; MemoryMB = 1024 }
            
            Mock Get-VM -ModuleName 'HyperV.Compute' -MockWith { return $null }
            Mock New-VM -ModuleName 'HyperV.Compute' -MockWith { param($Name, $MemoryStartupBytes, $ErrorAction) return [PSCustomObject]@{ Name = 'TestVM' } }
            Mock Set-VMProcessor -ModuleName 'HyperV.Compute' -MockWith { param($VMName, $Count, $ErrorAction) }
            Mock Write-Log -ModuleName 'HyperV.Compute' -MockWith { param($Message, $Level, $ContextData) }

            Assert-ComputeState -VMData $mockData

            Assert-MockCalled New-VM -ModuleName 'HyperV.Compute' -Times 1 -Exactly
            Assert-MockCalled Set-VMProcessor -ModuleName 'HyperV.Compute' -Times 1 -Exactly
        }
    }
}
