function Parse-InsperaLog {
    param(
        [string]$LogPath,
        [switch]$Verbose
    )

    $resolvedPath = Get-InsperaLogPath -LogPath $LogPath
    if (-not $resolvedPath) {
        return @{
            Found = $false
            LogPath = $null
            PrimaryFailure = $null
            Failures = @()
            Applications = @()
            SystemChecks = @()
            FailureDetails = @()
            Metadata = @{}
            Timeline = @()
            LastWriteTime = $null
            LineCount = 0
        }
    }

    $lines = Get-Content -Path $resolvedPath -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $lines) {
        $lines = Get-Content -Path $resolvedPath -ErrorAction SilentlyContinue
    }

    $patterns = Get-InsperaFailurePatterns
    $failures = [System.Collections.Generic.List[object]]::new()
    $lineNumber = 0

    foreach ($rawLine in $lines) {
        $lineNumber++
        $parsed = Parse-InsperaLogLine -Line $rawLine
        $haystack = "$rawLine $($parsed.Message)"

        foreach ($entry in $patterns) {
            if ($haystack -match $entry.Pattern) {
                $failures.Add([PSCustomObject]@{
                    Key = $entry.Key
                    Priority = $entry.Priority
                    LineNumber = $lineNumber
                    Timestamp = $parsed.Timestamp
                    Level = $parsed.Level
                    Module = $parsed.Module
                    Message = $parsed.Message
                    Raw = $rawLine
                })
            }
        }

        # System check lifecycle: Check "Environment" failed
        if ($parsed.Message -match '^Check\s+"?([^"]+)"?\s+(failed|failure)') {
            $checkKey = Get-InsperaCheckKeyFromName -CheckName $Matches[1]
            if ($checkKey) {
                $failures.Add([PSCustomObject]@{
                    Key = $checkKey
                    Priority = 10
                    LineNumber = $lineNumber
                    Timestamp = $parsed.Timestamp
                    Level = $parsed.Level
                    Module = $parsed.Module
                    Message = $parsed.Message
                    Raw = $rawLine
                })
            }
        }

        # Integrity module messages (fortknox / iceworm style)
        if ($haystack -match '\[(?:FortKnox|IceWorm|Integrity|SystemCheck)\].*(?:compromised|blocked|detected|failed|failure|virtual|remote session)') {
            if (-not ($failures | Where-Object { $_.LineNumber -eq $lineNumber })) {
                $failures.Add([PSCustomObject]@{
                    Key = 'Environment - failure'
                    Priority = 8
                    LineNumber = $lineNumber
                    Timestamp = $parsed.Timestamp
                    Level = $parsed.Level
                    Module = $parsed.Module
                    Message = $parsed.Message
                    Raw = $rawLine
                })
            }
        }

        if (Test-InsperaLineIsGenericFailureCandidate -Haystack $haystack -Message $parsed.Message) {
            if (-not ($failures | Where-Object { $_.LineNumber -eq $lineNumber })) {
                $failures.Add([PSCustomObject]@{
                    Key = 'unknown'
                    Priority = 0
                    LineNumber = $lineNumber
                    Timestamp = $parsed.Timestamp
                    Level = $parsed.Level
                    Module = $parsed.Module
                    Message = $parsed.Message
                    Raw = $rawLine
                })
            }
        }

        # IIB Go: clock offset beyond threshold
        if ($parsed.Message -match '^clock offset to NTP server ([-\d.]+)s') {
            $offset = [Math]::Abs([double]$Matches[1])
            if ($offset -gt 30) {
                $failures.Add([PSCustomObject]@{
                    Key = 'Clock accuracy - failure'
                    Priority = 10
                    LineNumber = $lineNumber
                    Timestamp = $parsed.Timestamp
                    Level = 'ERROR'
                    Module = $parsed.Module
                    Message = $parsed.Message
                    Raw = $rawLine
                })
            }
        }
    }

    $metadata = Get-InsperaLogMetadata -Lines $lines
    $primary = Select-InsperaPrimaryFailure -Failures $failures
    $applications = Get-InsperaApplicationsFromLog -Lines $lines
    $systemChecks = Get-InsperaSystemCheckEvents -Lines $lines
    $failureDetails = if ($primary) {
        Get-InsperaFailureDetailsFromLog -Lines $lines -FailureLineNumber $primary.LineNumber
    } else {
        @()
    }

    $fileInfo = Get-Item $resolvedPath

    return @{
        Found = $true
        LogPath = $resolvedPath
        PrimaryFailure = $primary
        Failures = @($failures)
        Applications = $applications
        SystemChecks = $systemChecks
        FailureDetails = $failureDetails
        Metadata = $metadata
        Timeline = if ($Verbose) { @($failures) } else { @() }
        LastWriteTime = $fileInfo.LastWriteTime
        LineCount = $lines.Count
    }
}
