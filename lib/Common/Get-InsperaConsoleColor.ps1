function Get-InsperaConsoleColor {
    param(
        [string]$Level,
        [string]$Line
    )

    if ($Line -match '^\[PASS\]') { return 'Green' }
    if ($Line -match '^\[FAIL\]') { return 'Red' }
    if ($Line -match '^\[WARN\]') { return 'Yellow' }

    switch ($Level) {
        'pass' { return 'Green' }
        'fail' { return 'Red' }
        'warn' { return 'Yellow' }
        'heading' { return 'Cyan' }
        default { return 'Gray' }
    }
}
