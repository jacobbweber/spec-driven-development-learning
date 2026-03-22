<#
.SYNOPSIS
    Thread-safe Logging Provider Class for parallel execution environments.

.DESCRIPTION
    The Logger class handles distributed, concurrent message writing to multiple outputs 
    (Console, Developer text logs, and JSON Aggregator logs). By encapsulating a 
    [System.Threading.Mutex], it guarantees that parallel Runspaces or background jobs 
    can safely append to the same physical file without throwing file-lock exceptions.

.EXAMPLE
    # Example 1: Basic Initialization and Logging
    $logDir = "C:\Logs"
    $logger = [Logger]::new($logDir)
    $logger.Write("Starting cleanup task", "INFO")

.EXAMPLE
    # Example 2: Writing with Context Metadata
    $contextMetadata = @{ VMName = "SQL-01"; Memory = "4GB" }
    $logger.Write("VM Drift detected", "WARN", "Assert-ComputeState", $contextMetadata)

.EXAMPLE
    # Example 3: Different Severity Levels
    $logger.Write("Connection failed", "ERROR")
    $logger.Write("Retrying API call...", "DEBUG")
#>
class Logger {
    [string]$DevLogPath
    [string]$AggLogPath
    [System.Threading.Mutex]$Mutex

    <#
    .SYNOPSIS
        Constructor for the Logger class.
    .DESCRIPTION
        Initializes the physical directory structures required for logging. Ensure the script
        has write permissions to the provided directory path.
    #>
    Logger([string]$LogDir) {
        $timestamp = Get-Date
        $todayStr = $timestamp.ToString("yyyyMMdd")
        $devDir = Join-Path $LogDir "Developer"
        $aggDir = Join-Path $LogDir "Aggregator"
        
        if (!(Test-Path $devDir)) { New-Item -ItemType Directory -Path $devDir -Force | Out-Null }
        if (!(Test-Path $aggDir)) { New-Item -ItemType Directory -Path $aggDir -Force | Out-Null }

        $this.DevLogPath = Join-Path $devDir "log_$todayStr.txt"
        $this.AggLogPath = Join-Path $aggDir "log_$todayStr.json"
        
        # A named mutex for cross-runspace thread-safety
        $this.Mutex = [System.Threading.Mutex]::new($false, "Global\PSLoggerMutex_$todayStr")
    }

    <#
    .SYNOPSIS
        Primary method to dispatch a log entry.
    .DESCRIPTION
        Takes a message, severity level, the calling component name, and an optional 
        hashtable of context metadata. Writes formatted strings to the DevLog and serialized
        JSON payloads to the AggLog concurrently using the Mutex.
    #>
    [void]Write([string]$Message, [string]$Level, [string]$Caller, [hashtable]$ContextData) {
        $timestamp = Get-Date
        $levelStr = if ([string]::IsNullOrWhiteSpace($Level)) { 'INFO' } else { $Level }
        $callerStr = if ([string]::IsNullOrWhiteSpace($Caller)) { 'Unknown' } else { $Caller }

        $contextStr = ""
        if ($null -ne $ContextData -and $ContextData.Count -gt 0) {
            $contextStrs = @()
            foreach ($key in $ContextData.Keys) {
                $contextStrs += "$key=$($ContextData[$key])"
            }
            $contextStr = " | Context: ($($contextStrs -join ', '))"
        }

        $devMessage = "[$($timestamp.ToString('yyyy-MM-dd HH:mm:ss.fff'))] [$levelStr] [$callerStr] $Message$contextStr"

        $jsonPayload = [ordered]@{
            Timestamp = $timestamp.ToString('O')
            Level     = $levelStr
            Origin    = $callerStr
            Message   = $Message
        }
        if ($null -ne $ContextData -and $ContextData.Count -gt 0) {
            $jsonPayload['Context'] = $ContextData
        }
        $jsonLine = $jsonPayload | ConvertTo-Json -Compress

        try {
            # Wait up to 5 seconds for the mutex lock
            if ($this.Mutex.WaitOne(5000)) {
                try {
                    [System.IO.File]::AppendAllText($this.DevLogPath, $devMessage + [Environment]::NewLine)
                    if ($levelStr -ne 'DEBUG') {
                        [System.IO.File]::AppendAllText($this.AggLogPath, $jsonLine + [Environment]::NewLine)
                    }
                } finally {
                    $this.Mutex.ReleaseMutex()
                }
            } else {
                Write-Warning "Logger Mutex timeout. Message dropped: $Message"
            }
        } catch {
            Write-Warning "Logger failed to write: $_"
        }

        # Console Output Handling
        $infoData = "[$levelStr] $Message"
        switch ($levelStr) {
            'INFO'  { Write-Information $infoData -InformationAction Continue }
            'WARN'  { Write-Warning $infoData }
            'ERROR' { Write-Error $infoData }
            'DEBUG' { Write-Debug $infoData }
        }
    }

    <#
    .SYNOPSIS
        Overloaded Write methods for simpler invocation syntax.
    #>
    [void]Write([string]$Message, [string]$Level, [string]$Caller) {
        $this.Write($Message, $Level, $Caller, $null)
    }

    [void]Write([string]$Message, [string]$Level) {
        $this.Write($Message, $Level, 'Unknown', $null)
    }

    [void]Write([string]$Message) {
        $this.Write($Message, 'INFO', 'Unknown', $null)
    }
}
