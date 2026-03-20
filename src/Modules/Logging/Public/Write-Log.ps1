function Write-Log {
    <#
    .SYNOPSIS
        Writes a message to the centralized logging infrastructure.
    .DESCRIPTION
        Outputs log messages to the console, a developer text log, and an aggregator JSON log. Supports multiple logging levels and optional context data for rich JSON logs. Handles underlying file writes using thread-safe non-locking logic.
    .EXAMPLE
        Write-Log -Message "Starting process" -Level INFO
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]
        [string] $Level = 'INFO',

        [Parameter(Mandatory = $false)]
        [hashtable] $ContextData
    )

    process {
        $timestamp = Get-Date
        $todayStr = $timestamp.ToString("yyyyMMdd")
        $devLogPath = Join-Path $script:DevLogDir "log_$todayStr.txt"
        $aggLogPath = Join-Path $script:AggLogDir "log_$todayStr.json"

        # Determine Caller
        $caller = $MyInvocation.ScriptName
        if ([string]::IsNullOrEmpty($caller)) {
            $caller = "Console"
        } else {
            $caller = Split-Path $caller -Leaf
        }

        # 1. Developer Text Log (All levels)
        $contextStr = if ($null -ne $ContextData) { " | Context: ($($ContextData.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" } | Join-String -Separator ', '))" } else { "" }
        $devMessage = "[$($timestamp.ToString('yyyy-MM-dd HH:mm:ss.fff'))] [$Level] [$caller] $Message$contextStr"
        
        try {
            [System.IO.File]::AppendAllText($devLogPath, $devMessage + [Environment]::NewLine)
        } catch { 
            # Fail-safe lock handling
            Write-Warning "Failed to write to Developer log: $_"
        }

        # 2. Aggregator JSON Log (Skip DEBUG)
        if ($Level -ne 'DEBUG') {
            $jsonPayload = [ordered]@{
                Timestamp = $timestamp.ToString('O')
                Level = $Level
                Origin = $caller
                Message = $Message
            }
            if ($null -ne $ContextData) {
                $jsonPayload.Add('Context', $ContextData)
            }
            
            $jsonLine = $jsonPayload | ConvertTo-Json -Compress
            try {
                [System.IO.File]::AppendAllText($aggLogPath, $jsonLine + [Environment]::NewLine)
            } catch { 
                # Fail-safe lock handling
                Write-Warning "Failed to write to Aggregator log: $_"
            }
        }

        # 3. Console Output (Using Write-Information to avoid ScriptAnalyzer warnings on Write-Host)
        # However, Write-Information doesn't natively support colors in the same way, but conforms to strict rules.
        $infoData = "[$Level] $Message"
        switch ($Level) {
            'INFO'  { Write-Information $infoData -InformationAction Continue }
            'WARN'  { Write-Warning $infoData }
            'ERROR' { Write-Error $infoData }
            'DEBUG' { 
                if ($DebugPreference -ne 'SilentlyContinue') {
                    Write-Information $infoData -InformationAction Continue
                }
            }
        }
    }
}
