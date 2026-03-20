# Logging Infrastructure Specification

## 1. Abstract
This specification defines the behavior of the `Write-Log` function within the `Logging` module, responsible for generating all script output.

## 2. Properties
- **Location**: `src\Modules\Logging\Logging.psm1`
- **Cmdlet Name**: `Write-Log`
- **Dependencies**: None.

## 3. Input Parameters
- `Message`: `[string]` (Mandatory). The core event message.
- `Level`: `[ValidateSet('INFO', 'WARN', 'ERROR', 'DEBUG')]` (Default: 'INFO'). The severity of the event.
- `ContextData`: `[hashtable]` (Optional). Additional structured data (e.g., VM Name, Property Name) to log.

## 4. Log Destinations (The 3 Streams)
The function must simultaneously output to three distinct channels upon execution.

### 4.1 Developer Text Log
- **Location**: `Logs\Developer\log_<date>.txt`
- **Format**: `[Timestamp] [Level] [Caller] Message - Context`
- **Purpose**: Full diagnostic trace. Every `Write-Log` call, including `DEBUG` levels, is written here.

### 4.2 Aggregator JSON Log
- **Location**: `Logs\Aggregator\log_<date>.json`
- **Format**: JSON Lines (one JSON object per line).
- **Properties**: `Timestamp`, `Level`, `Message`, `ContextData` (expanded).
- **Purpose**: Machine ingest for tools like Splunk. `DEBUG` level messages are excluded.

### 4.3 Console Output
- **Target**: PowerShel Host (using `Write-Host` or native output streams)
- **Format**: `[Level] Message`
- **Colors**: Cyan (INFO), Yellow (WARN), Red (ERROR). DarkGray (DEBUG, only if `$DebugPreference` allows).
- **Purpose**: Live user feedback.

## 5. Retention & Rotation Algorithm
Upon module import or script start, a maintenance routine must execute:

1. **Rotation**: Current active logs (Text/JSON) roll over daily by naming convention `log_yyyyMMdd`.
2. **Archiving**:
   - Check the `Logs\Developer` and `Logs\Aggregator` folders.
   - For all files older than current day, move them to `Logs\archive\yyyy-MM-dd\`.
3. **Pruning**:
   - Calculate total size of `Logs\archive`. If `> 1GB`, delete the oldest `\archive\[date]` folder until size is `< 1GB`.
   - Iterate over `Logs\archive\[date]` folders. If `[date]` is older than 30 days from `$Now`, delete the folder.

## 6. Implementation Notes
- Operations within `Write-Log` regarding file access must handle concurrent locks gracefully (or fail-safe so logging doesn't crash the script).
