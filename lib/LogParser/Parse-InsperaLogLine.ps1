function Parse-InsperaLogLine {
    param([string]$Line)

    $result = @{
        Raw = $Line
        Timestamp = $null
        Level = $null
        Module = $null
        Message = $Line.Trim()
        Json = $null
    }

    if ([string]::IsNullOrWhiteSpace($Line)) {
        return $result
    }

    # IIB Go launcher: 2026/06/09 22:47:09 launching Inspera Integrity Browser v1.16.3
    if ($Line -match '^(\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) (.+)$') {
        $result.Timestamp = $Matches[1]
        $result.Message = $Matches[2]
        if ($result.Message -match '^Fyne error:|^GLFW poll event error|iceworm exited: exit status [1-9]|^cancellation detected') {
            $result.Level = 'ERROR'
        } elseif ($result.Message -match '^iceworm:') {
            $result.Module = 'iceworm'
            if ($result.Message -match 'Info:') { $result.Level = 'INFO' }
            if ($result.Message -match 'Error:|Warn:') { $result.Level = 'ERROR' }
        }
        return $result
    }

    # electron-log: [2024-03-15 09:12:34.123] [info] message
    if ($Line -match '^\[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?)\]\s+\[(\w+)\]\s+(.*)$') {
        $result.Timestamp = $Matches[1]
        $result.Level = $Matches[2]
        $result.Message = $Matches[3]
        return $result
    }

    # SEB-style / structured: 2024-10-07 14:14:17.628 [09] - INFO: [Module] message
    if ($Line -match '^(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}(?:\.\d+)?)\s+\[(\d+)\]\s+-\s+(\w+):\s+(?:\[([^\]]+)\]\s+)?(.*)$') {
        $result.Timestamp = $Matches[1]
        $result.Level = $Matches[3]
        $result.Module = $Matches[4]
        $result.Message = $Matches[5]
        return $result
    }

    # ISO bracketed: 2026-06-09T10:15:01.123Z [INFO] message
    if ($Line -match '^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?)\s+\[(\w+)\]\s+(.*)$') {
        $result.Timestamp = $Matches[1]
        $result.Level = $Matches[2]
        $result.Message = $Matches[3]
        return $result
    }

    # Generic timestamp prefix
    if ($Line -match '^\[?(\d{4}[-/]\d{2}[-/]\d{2}[T\s]\d{2}:\d{2}:\d{2}[^\]]*)\]?\s*(.*)$') {
        $result.Timestamp = $Matches[1]
        $result.Message = $Matches[2]
    }

    if ($Line -match '^\s*\{.*\}\s*$') {
        try {
            $json = $Line | ConvertFrom-Json
            $result.Json = $json
            if ($json.level) { $result.Level = $json.level }
            if ($json.message) { $result.Message = $json.message }
            if ($json.msg) { $result.Message = $json.msg }
            if ($json.timestamp) { $result.Timestamp = $json.timestamp }
            if ($json.module) { $result.Module = $json.module }
            if ($json.context) { $result.Module = $json.context }
        } catch {
            # keep raw line
        }
    }

    if (-not $result.Level -and $result.Message -match '\b(ERROR|ERR|WARN|WARNING|INFO|DEBUG|FATAL)\b') {
        $result.Level = $Matches[1]
    }

    return $result
}
