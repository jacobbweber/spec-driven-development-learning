Describe 'HyperV.Storage Unit Tests' {
    BeforeAll {
        . "$PSScriptRoot\..\..\src\Classes\Logger.ps1"
        . "$PSScriptRoot\..\..\src\Classes\Telemetry.ps1"
        . "$PSScriptRoot\..\..\src\Classes\Context.ps1"

        $modulePath = Join-Path $PSScriptRoot "..\..\src\Modules\HyperV.Storage\HyperV.Storage.psm1"
        Import-Module $modulePath -Force

        $script:tempLogDir = Join-Path $env:TEMP "PesterLogs_Storage_$(Get-Random)"
        $script:context = [Context]::new($script:tempLogDir)
    }

    AfterAll {
        if (Test-Path $script:tempLogDir) { Remove-Item -Path $script:tempLogDir -Recurse -Force }
    }

    Context 'Assert-StorageState' {
        It 'Mocks New-VHD when state is Present' {
            $mockData = [PSCustomObject]@{ Path = 'C:\fake.vhdx'; State = 'Present' }
            
            Mock Get-VHD -ModuleName 'HyperV.Storage' { return $null }
            Mock New-VHD -ModuleName 'HyperV.Storage' {}

            Assert-StorageState -StorageData $mockData -Context $script:context

            Assert-MockCalled New-VHD -ModuleName 'HyperV.Storage' -Times 1 -Exactly
        }
    }
}
