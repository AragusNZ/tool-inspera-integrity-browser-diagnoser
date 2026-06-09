function Convert-InsperaCheckToLine {
    param($Check)

    [string[]]$lines = @()

    if ($Check.Warnings -and $Check.Warnings.Count -gt 0) {
        $lines = @($Check.Warnings | ForEach-Object { "[WARN] $_" })
    } elseif ($Check.Name -eq 'Keyboard language') {
        $lines = @("[INFO] $($Check.Name): $($Check.Message)")
    } elseif ($Check.Passed) {
        $lines = @("[PASS] $($Check.Name): $($Check.Message)")
    } else {
        $lines = @("[FAIL] $($Check.Name): $($Check.Message)")
    }

    return $lines
}
