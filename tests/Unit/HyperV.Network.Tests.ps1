Describe "Assert-NetworkState" {
    BeforeAll {
        . "$PSScriptRoot\..\..\src\Classes\Logger.ps1"
        . "$PSScriptRoot\..\..\src\Classes\Telemetry.ps1"
        . "$PSScriptRoot\..\..\src\Classes\Context.ps1"

        $modulePath = "$PSScriptRoot\..\..\src\Modules\HyperV.Network\HyperV.Network.psm1"
        Import-Module $modulePath -Force

        $script:tempLogDir = Join-Path $env:TEMP "PesterLogs_Network_$(Get-Random)"
        $script:context = [Context]::new($script:tempLogDir)
    }

    AfterAll {
        if (Test-Path $script:tempLogDir) { Remove-Item -Path $script:tempLogDir -Recurse -Force }
    }

    Context "When Desired State is Present" {
        It "Should create the switch if it does not exist" {
            Mock Get-VMSwitch -ModuleName 'HyperV.Network' -MockWith { return $null }
            Mock New-VMSwitch -ModuleName 'HyperV.Network' -MockWith { param($Name, $SwitchType, $ErrorAction) }

            $switchData = [PSCustomObject]@{
                Name = 'TestSwitch'
                State = 'Present'
                SwitchType = 'Private'
            }

            Assert-NetworkState -SwitchData $switchData -Context $script:context

            Assert-MockCalled Get-VMSwitch -ModuleName 'HyperV.Network' -Times 1 -ParameterFilter { $Name -eq 'TestSwitch' }
            Assert-MockCalled New-VMSwitch -ModuleName 'HyperV.Network' -Times 1 -ParameterFilter { $Name -eq 'TestSwitch' -and $SwitchType -eq 'Private' }
        }

        It "Should skip creation if the switch already exists in desired state" {
            Mock Get-VMSwitch -ModuleName 'HyperV.Network' -MockWith { return [PSCustomObject]@{ SwitchType = 'Private' } }
            Mock New-VMSwitch -ModuleName 'HyperV.Network' -MockWith { param($Name, $SwitchType, $ErrorAction) }

            $switchData = [PSCustomObject]@{
                Name = 'TestSwitch'
                State = 'Present'
                SwitchType = 'Private'
            }

            Assert-NetworkState -SwitchData $switchData -Context $script:context

            Assert-MockCalled Get-VMSwitch -ModuleName 'HyperV.Network' -Times 1
            Assert-MockCalled New-VMSwitch -ModuleName 'HyperV.Network' -Times 0
        }
    }

    Context "When Desired State is Absent" {
        It "Should remove the switch if it exists" {
            Mock Get-VMSwitch -ModuleName 'HyperV.Network' -MockWith { return [PSCustomObject]@{ Name = 'TestSwitch' } }
            Mock Remove-VMSwitch -ModuleName 'HyperV.Network' -MockWith { param($Name, $Force, $ErrorAction) }

            $switchData = [PSCustomObject]@{
                Name = 'TestSwitch'
                State = 'Absent'
            }

            Assert-NetworkState -SwitchData $switchData -Context $script:context

            Assert-MockCalled Get-VMSwitch -ModuleName 'HyperV.Network' -Times 1
            Assert-MockCalled Remove-VMSwitch -ModuleName 'HyperV.Network' -Times 1 -ParameterFilter { $Name -eq 'TestSwitch' }
        }

        It "Should skip removal if the switch already does not exist" {
            Mock Get-VMSwitch -ModuleName 'HyperV.Network' -MockWith { return $null }
            Mock Remove-VMSwitch -ModuleName 'HyperV.Network' -MockWith { param($Name, $Force, $ErrorAction) }

            $switchData = [PSCustomObject]@{
                Name = 'TestSwitch'
                State = 'Absent'
            }

            Assert-NetworkState -SwitchData $switchData -Context $script:context

            Assert-MockCalled Get-VMSwitch -ModuleName 'HyperV.Network' -Times 1
            Assert-MockCalled Remove-VMSwitch -ModuleName 'HyperV.Network' -Times 0
        }
    }
}
