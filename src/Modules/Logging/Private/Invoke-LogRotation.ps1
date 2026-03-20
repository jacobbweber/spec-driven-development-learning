function Invoke-LogRotation {
    <#
    .SYNOPSIS
        Rotates logs older than today into the Archive directory.
    .DESCRIPTION
        Prunes archives older than 30 days or if total size exceeds 1GB. Keeps the primary log directories clean and manages long-term storage of logs effectively.
    .EXAMPLE
        Invoke-LogRotation
    #>
    [CmdletBinding()]
    param()

    process {
        $todayStr = (Get-Date).ToString("yyyyMMdd")
        
        # 1. Rotate to Archive
        $allLogs = Get-ChildItem -Path $script:DevLogDir, $script:AggLogDir -File
        foreach ($file in $allLogs) {
            # Format: log_yyyyMMdd.*
            if ($file.Name -notmatch "log_$todayStr") {
                # Extract date from filename if possible
                if ($file.Name -match "log_(?<date>\d{8})") {
                    $fileDateStr = $matches.date
                    $archiveDateDir = Join-Path $script:ArchiveDir $fileDateStr
                    if (-not (Test-Path $archiveDateDir)) {
                        New-Item -ItemType Directory -Force -Path $archiveDateDir | Out-Null
                    }
                    try {
                        Move-Item -Path $file.FullName -Destination $archiveDateDir -Force -ErrorAction Stop
                    } catch {
                        # Fail-safe, logging rotation shouldn't break the main thread
                        Write-Warning "Failed to archive log file $($file.Name): $_"
                    }
                }
            }
        }

        # 2. Prune by Age (30 Days)
        $cutoffDate = (Get-Date).AddDays(-30)
        $archiveFolders = Get-ChildItem -Path $script:ArchiveDir -Directory
        foreach ($folder in $archiveFolders) {
            # Rely on folder CreationTime or parsed name
            if ($folder.CreationTime -lt $cutoffDate) {
                Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        # 3. Prune by Size (1GB)
        $totalSizeBytes = (Get-ChildItem -Path $script:ArchiveDir -Recurse -File | Measure-Object -Property Length -Sum).Sum
        $maxSizeBytes = 1GB

        while ($totalSizeBytes -gt $maxSizeBytes) {
            # Find the oldest folder to delete
            $oldestFolder = Get-ChildItem -Path $script:ArchiveDir -Directory | Sort-Object CreationTime | Select-Object -First 1
            if ($null -ne $oldestFolder) {
                $folderSize = (Get-ChildItem -Path $oldestFolder.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum
                Remove-Item -Path $oldestFolder.FullName -Recurse -Force -ErrorAction SilentlyContinue
                $totalSizeBytes -= $folderSize
            } else {
                break
            }
        }
    }
}
