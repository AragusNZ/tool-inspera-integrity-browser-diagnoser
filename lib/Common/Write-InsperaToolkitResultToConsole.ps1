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
            $fg = Get-InsperaConsoleColor -Level $section.Level -Line $line
            Write-Host "  $line" -ForegroundColor $fg
        }
        Write-Host ''
    }
}
