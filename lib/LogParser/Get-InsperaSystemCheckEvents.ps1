function Get-InsperaSystemCheckEvents {
    param([string[]]$Lines)

    $events = [System.Collections.Generic.List[object]]::new()
    $lineNumber = 0

    foreach ($rawLine in $Lines) {
        $lineNumber++
        $parsed = Parse-InsperaLogLine -Line $rawLine
        $text = $parsed.Message

        if ($text -match '^(?:Running|Starting)\s+(?:system\s+)?check:?\s*"?([^"]+)"?$') {
            $events.Add([PSCustomObject]@{
                Type = 'start'
                Check = $Matches[1].Trim()
                LineNumber = $lineNumber
                Raw = $rawLine
            })
            continue
        }

        if ($text -match '^Check\s+"?([^"]+)"?\s+(?:started|running)') {
            $events.Add([PSCustomObject]@{
                Type = 'start'
                Check = $Matches[1].Trim()
                LineNumber = $lineNumber
                Raw = $rawLine
            })
            continue
        }

        if ($text -match '^([A-Za-z][\w\s]+)\s*-\s*(success|passed)') {
            $events.Add([PSCustomObject]@{
                Type = 'pass'
                Check = $Matches[1].Trim()
                LineNumber = $lineNumber
                Raw = $rawLine
            })
            continue
        }

        if ($text -match '^([A-Za-z][\w\s]+)\s*-\s*(failure|failed)') {
            $events.Add([PSCustomObject]@{
                Type = 'fail'
                Check = $Matches[1].Trim()
                LineNumber = $lineNumber
                Raw = $rawLine
            })
            continue
        }

        # IIB Go launcher session flow
        if ($text -match '^launching Inspera Integrity Browser v') {
            $events.Add([PSCustomObject]@{ Type = 'info'; Check = 'Launcher start'; LineNumber = $lineNumber; Raw = $rawLine })
            continue
        }
        if ($text -match '^entering sys setup page') {
            $events.Add([PSCustomObject]@{ Type = 'start'; Check = 'System check'; LineNumber = $lineNumber; Raw = $rawLine })
            continue
        }
        if ($text -match '^session status (.+)') {
            $events.Add([PSCustomObject]@{ Type = 'info'; Check = "Session: $($Matches[1])"; LineNumber = $lineNumber; Raw = $rawLine })
            continue
        }
        if ($text -match '^VM check') {
            $events.Add([PSCustomObject]@{ Type = 'info'; Check = 'VM check'; LineNumber = $lineNumber; Raw = $rawLine })
            continue
        }
        if ($text -match '^clock offset to NTP server') {
            $events.Add([PSCustomObject]@{ Type = 'info'; Check = 'Clock NTP'; LineNumber = $lineNumber; Raw = $rawLine })
            continue
        }
        if ($text -match '^active displays') {
            $events.Add([PSCustomObject]@{ Type = 'info'; Check = 'Displays'; LineNumber = $lineNumber; Raw = $rawLine })
            continue
        }
        if ($text -match '^iceworm exited:') {
            $events.Add([PSCustomObject]@{ Type = 'fail'; Check = 'iceworm'; LineNumber = $lineNumber; Raw = $rawLine })
            continue
        }
        if ($text -match '^cancellation detected') {
            $events.Add([PSCustomObject]@{ Type = 'fail'; Check = 'Check cancelled'; LineNumber = $lineNumber; Raw = $rawLine })
        }
    }

    return @($events)
}
