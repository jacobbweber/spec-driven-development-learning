Describe 'Invoke-HyperVSync Integration Tests' {
    BeforeAll {
        $script:controllerPath = Join-Path $PSScriptRoot "..\..\src\Invoke-HyperVSync.ps1"
        $script:stateFile = Join-Path $PSScriptRoot "..\..\Example\state.json"
        
        Import-Module (Join-Path $PSScriptRoot "..\..\src\Modules\HyperV.Network\HyperV.Network.psm1") -Force
        Import-Module (Join-Path $PSScriptRoot "..\..\src\Modules\HyperV.Storage\HyperV.Storage.psm1") -Force
        Import-Module (Join-Path $PSScriptRoot "..\..\src\Modules\HyperV.Compute\HyperV.Compute.psm1") -Force
        Import-Module (Join-Path $PSScriptRoot "..\..\src\Modules\Logging\Logging.psm1") -Force
    }

    Context 'Parameter Validation and Error Handling' {
        It 'Throws if StateFilePath is invalid' {
            { & $script:controllerPath -StateFilePath "C:\NonExistentFile.json" } | Should -Throw "State file not found at*"
        }
    }

    Context 'Execution orchestration' {
        It 'Calls Domain Asserts for components defined in the JSON' {
            Mock Import-Module {}
            Mock Assert-NetworkState {}
            Mock Assert-StorageState {}
            Mock Assert-ComputeState {}
            Mock Write-Log {}

            & $script:controllerPath -StateFilePath $script:stateFile

            # state.json has 1 Switch, 1 Disk, 2 VMs defined.
            Assert-MockCalled Assert-NetworkState -Times 1 -Exactly
            Assert-MockCalled Assert-StorageState -Times 1 -Exactly
            Assert-MockCalled Assert-ComputeState -Times 2 -Exactly
        }
    }
}
