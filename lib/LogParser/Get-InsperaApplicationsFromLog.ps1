function Get-InsperaApplicationsFromLog {
    param([string[]]$Lines)

    $apps = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    $appPatterns = @(
        'failed to close(?:\s+the following applications)?[:\s]+(.+)$',
        'Inspera failed to close the following applications[:\s.]+(.+)$',
        'detected the following applications(?: that have access to Screen Capture)?[^:]*:\s*(.+)$',
        'prohibited[^:]*:\s*(.+)$',
        'blocklist[^:]*:\s*(.+)$',
        'running processes?[:\s]+(.+)$',
        'could not terminate[:\s]+(.+)$',
        'blocked processes?[:\s]+(.+)$'
    )

    foreach ($line in $Lines) {
        foreach ($pattern in $appPatterns) {
            if ($line -match $pattern) {
                $chunk = $Matches[1]
                $parts = $chunk -split '[,;|\[\]"]+' | ForEach-Object { $_.Trim() } |
                    Where-Object { $_ -match '\.(exe|app)$|^[A-Za-z][\w\s.-]{2,}$' }
                foreach ($part in $parts) {
                    [void]$apps.Add($part)
                }
            }
        }

        if ($line -match '"process(?:Name)?"\s*:\s*"([^"]+)"') {
            [void]$apps.Add($Matches[1])
        }
        if ($line -match '"application"\s*:\s*"([^"]+)"') {
            [void]$apps.Add($Matches[1])
        }
        if ($line -match '"executable"\s*:\s*"([^"]+)"') {
            [void]$apps.Add($Matches[1])
        }

        # JSON array of process names: ["Discord.exe","obs64.exe"]
        if ($line -match '\[(?:\s*"[^"]+"\s*,?)+\]') {
            $matches = [regex]::Matches($line, '"([^"]+\.(?:exe|app))"')
            foreach ($m in $matches) {
                [void]$apps.Add($m.Groups[1].Value)
            }
        }
    }

    return @($apps)
}
