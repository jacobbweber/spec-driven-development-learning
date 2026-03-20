Describe 'HyperV.Storage Unit Tests' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot "..\..\src\Modules\HyperV.Storage\HyperV.Storage.psm1"
        $loggingModulePath = Join-Path $PSScriptRoot "..\..\src\Modules\Logging\Logging.psm1"
        Import-Module $modulePath -Force
        Import-Module $loggingModulePath -Force
    }

    Context 'Assert-StorageState' {
        It 'Mocks New-VHD when state is Present' {
            $mockData = [PSCustomObject]@{ Path = 'C:\fake.vhdx'; State = 'Present' }
            
            Mock Get-VHD -ModuleName 'HyperV.Storage' { return $null }
            Mock New-VHD -ModuleName 'HyperV.Storage' {}
            Mock Write-Log -ModuleName 'HyperV.Storage' {}

            Assert-StorageState -StorageData $mockData

            Assert-MockCalled New-VHD -ModuleName 'HyperV.Storage' -Times 1 -Exactly
        }
    }
}
