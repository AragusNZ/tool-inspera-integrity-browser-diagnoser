function Write-InsperaToolkitResultToConsole {
    param($Result)

    Write-InsperaHeader $Result.Title

    if ($Result.Summary) {
        $color = switch ($Result.Status) {
            'ok' { 'Green' }
            'issues' { 'Yellow' }
            'error' { 'Red' }
            default { 'White' }
        }
        Write-Host $Result.Summary -ForegroundColor $color
        Write-Host ''
    }

    foreach ($section in $Result.Sections) {
        if ($section.Heading) {
            Write-Host $section.Heading -ForegroundColor Cyan
        }
        foreach ($line in $section.Lines) {
            $fg = switch ($section.Level) {
                'pass' { 'Green' }
                'fail' { 'Red' }
                'warn' { 'Yellow' }
                'heading' { 'Cyan' }
                default { 'Gray' }
            }
            if ($line -match '^\[PASS\]') { $fg = 'Green' }
            elseif ($line -match '^\[FAIL\]') { $fg = 'Red' }
            elseif ($line -match '^\[WARN\]') { $fg = 'Yellow' }
            Write-Host "  $line" -ForegroundColor $fg
        }
        Write-Host ''
    }
}
