Describe 'Logging Unit Tests' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot "..\..\src\Modules\Logging\Logging.psm1"
        Import-Module $modulePath -Force

        # The module intrinsically writes to src\Logs
        $script:actualLogsDir = Join-Path $PSScriptRoot "..\..\src\Logs"
    }

    Context 'Infrastructure Initialization' {
        It 'Creates the required directories upon import' {
            InModuleScope 'Logging' { Initialize-LoggingInfrastructure }
            (Test-Path (Join-Path $script:actualLogsDir "Developer")) | Should -BeTrue
            (Test-Path (Join-Path $script:actualLogsDir "Aggregator")) | Should -BeTrue
            (Test-Path (Join-Path $script:actualLogsDir "Archive")) | Should -BeTrue
        }
    }

    Context 'Write-Log output routing' {
        BeforeEach {
            # Clear logs before test
            Get-ChildItem -Path (Join-Path $script:actualLogsDir "Developer") -File -ErrorAction SilentlyContinue | Remove-Item -Force
            Get-ChildItem -Path (Join-Path $script:actualLogsDir "Aggregator") -File -ErrorAction SilentlyContinue | Remove-Item -Force
        }

        It 'Writes INFO level to both Dev and Aggregator logs' {
            InModuleScope 'Logging' { Initialize-LoggingInfrastructure }
            Write-Log -Message "Test Info" -Level INFO

            $todayStr = (Get-Date).ToString("yyyyMMdd")
            $devLogs = @(Get-ChildItem -Path (Join-Path $script:actualLogsDir "Developer") -Filter "log_$todayStr.txt" -ErrorAction SilentlyContinue)
            $aggLogs = @(Get-ChildItem -Path (Join-Path $script:actualLogsDir "Aggregator") -Filter "log_$todayStr.json" -ErrorAction SilentlyContinue)

            $devLogs.Count | Should -Be 1
            $aggLogs.Count | Should -Be 1

            $devContent = Get-Content $devLogs[0].FullName -Raw
            $devContent | Should -Match "Test Info"
            $devContent | Should -Match "\[INFO\]"
        }

        It 'Does not write DEBUG level to Aggregator logs' {
            Write-Log -Message "Test Debug" -Level DEBUG

            $todayStr = (Get-Date).ToString("yyyyMMdd")
            $devLogs = @(Get-ChildItem -Path (Join-Path $script:actualLogsDir "Developer") -Filter "log_$todayStr.txt" -ErrorAction SilentlyContinue)
            $aggLogs = @(Get-ChildItem -Path (Join-Path $script:actualLogsDir "Aggregator") -Filter "log_$todayStr.json" -ErrorAction SilentlyContinue)

            $devLogs.Count | Should -Be 1

            if ($aggLogs.Count -gt 0) {
                $aggContent = Get-Content $aggLogs[0].FullName -Raw
                $aggContent | Should -Not -Match "Test Debug"
            }
        }
    }
}
