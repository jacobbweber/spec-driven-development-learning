Describe "Context and Provider Classes Unit Tests" {
    BeforeAll {
        . "$PSScriptRoot\..\..\src\Classes\Logger.ps1"
        . "$PSScriptRoot\..\..\src\Classes\Telemetry.ps1"
        . "$PSScriptRoot\..\..\src\Classes\Context.ps1"
        
        $script:tempLogDir = Join-Path $env:TEMP "PesterLogs_Context_$(Get-Random)"
    }

    AfterAll {
        if (Test-Path $script:tempLogDir) { Remove-Item -Path $script:tempLogDir -Recurse -Force }
    }

    Context "Logger Class" {
        It "Initializes log paths correctly" {
            $logger = [Logger]::new($script:tempLogDir)
            $logger.DevLogPath | Should -Match "log_.*\.txt"
            $logger.AggLogPath | Should -Match "log_.*\.json"
            (Test-Path (Split-Path $logger.DevLogPath -Parent)) | Should -Be $true
        }

        It "Writes context to JSON and text" {
            $logger = [Logger]::new($script:tempLogDir)
            $ctx = @{ TestKey = "TestValue" }
            $logger.Write("Test message", "INFO", "TestCaller", $ctx)

            $textContent = Get-Content $logger.DevLogPath -Raw
            $textContent | Should -Match "Test message"
            $textContent | Should -Match "TestValue"

            $jsonContent = Get-Content $logger.AggLogPath | ConvertFrom-Json
            $jsonContent.Message | Should -Be "Test message"
            $jsonContent.Context.TestKey | Should -Be "TestValue"
        }
    }

    Context "Telemetry Class" {
        It "Tracks events and exports JSON" {
            $telemetry = [Telemetry]::new()
            $telemetry.TrackEvent("CategoryA", "ActionA", @{ SubType = "Create" })

            $exportPath = Join-Path $script:tempLogDir "telemetry.json"
            $telemetry.Export($exportPath)

            (Test-Path $exportPath) | Should -Be $true
            $jsonContent = Get-Content $exportPath | ConvertFrom-Json
            $jsonContent.Category | Should -Be "CategoryA"
            $jsonContent.Action | Should -Be "ActionA"
            $jsonContent.SubType | Should -Be "Create"
        }
    }

    Context "Context Class" {
        It "Initializes with default Remediate mode and instantiates providers" {
            $ctx = [Context]::new($script:tempLogDir)
            $ctx.Mode | Should -Be "Remediate"
            $null -ne $ctx.Logger | Should -Be $true
            $null -ne $ctx.Telemetry | Should -Be $true
        }
    }
}
