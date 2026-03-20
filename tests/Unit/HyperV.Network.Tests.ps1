Describe "Assert-NetworkState" {
    BeforeAll {
        $modulePath = "$PSScriptRoot\..\..\src\Modules\HyperV.Network\HyperV.Network.psm1"
        $loggingModulePath = "$PSScriptRoot\..\..\src\Modules\Logging\Logging.psm1"
        Import-Module $modulePath -Force
        Import-Module $loggingModulePath -Force
    }

    Context "When Desired State is Present" {
        It "Should create the switch if it does not exist" {
            Mock Get-VMSwitch -ModuleName 'HyperV.Network' -MockWith { return $null }
            Mock New-VMSwitch -ModuleName 'HyperV.Network' -MockWith { param($Name, $SwitchType, $ErrorAction) }
            Mock Write-Log -ModuleName 'HyperV.Network' -MockWith { param($Message, $Level, $ContextData) }

            $switchData = [PSCustomObject]@{
                Name = 'TestSwitch'
                State = 'Present'
                SwitchType = 'Private'
            }

            Assert-NetworkState -SwitchData $switchData

            Assert-MockCalled Get-VMSwitch -ModuleName 'HyperV.Network' -Times 1 -ParameterFilter { $Name -eq 'TestSwitch' }
            Assert-MockCalled New-VMSwitch -ModuleName 'HyperV.Network' -Times 1 -ParameterFilter { $Name -eq 'TestSwitch' -and $SwitchType -eq 'Private' }
        }

        It "Should skip creation if the switch already exists in desired state" {
            Mock Get-VMSwitch -ModuleName 'HyperV.Network' -MockWith { return [PSCustomObject]@{ SwitchType = 'Private' } }
            Mock New-VMSwitch -ModuleName 'HyperV.Network' -MockWith { param($Name, $SwitchType, $ErrorAction) }
            Mock Write-Log -ModuleName 'HyperV.Network' -MockWith { param($Message, $Level, $ContextData) }

            $switchData = [PSCustomObject]@{
                Name = 'TestSwitch'
                State = 'Present'
                SwitchType = 'Private'
            }

            Assert-NetworkState -SwitchData $switchData

            Assert-MockCalled Get-VMSwitch -ModuleName 'HyperV.Network' -Times 1
            Assert-MockCalled New-VMSwitch -ModuleName 'HyperV.Network' -Times 0
        }
    }

    Context "When Desired State is Absent" {
        It "Should remove the switch if it exists" {
            Mock Get-VMSwitch -ModuleName 'HyperV.Network' -MockWith { return [PSCustomObject]@{ Name = 'TestSwitch' } }
            Mock Remove-VMSwitch -ModuleName 'HyperV.Network' -MockWith { param($Name, $Force, $ErrorAction) }
            Mock Write-Log -ModuleName 'HyperV.Network' -MockWith { param($Message, $Level, $ContextData) }

            $switchData = [PSCustomObject]@{
                Name = 'TestSwitch'
                State = 'Absent'
            }

            Assert-NetworkState -SwitchData $switchData

            Assert-MockCalled Get-VMSwitch -ModuleName 'HyperV.Network' -Times 1
            Assert-MockCalled Remove-VMSwitch -ModuleName 'HyperV.Network' -Times 1 -ParameterFilter { $Name -eq 'TestSwitch' }
        }

        It "Should skip removal if the switch already does not exist" {
            Mock Get-VMSwitch -ModuleName 'HyperV.Network' -MockWith { return $null }
            Mock Remove-VMSwitch -ModuleName 'HyperV.Network' -MockWith { param($Name, $Force, $ErrorAction) }
            Mock Write-Log -ModuleName 'HyperV.Network' -MockWith { param($Message, $Level, $ContextData) }

            $switchData = [PSCustomObject]@{
                Name = 'TestSwitch'
                State = 'Absent'
            }

            Assert-NetworkState -SwitchData $switchData

            Assert-MockCalled Get-VMSwitch -ModuleName 'HyperV.Network' -Times 1
            Assert-MockCalled Remove-VMSwitch -ModuleName 'HyperV.Network' -Times 0
        }
    }
}
