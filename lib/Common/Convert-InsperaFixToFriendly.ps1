function Convert-InsperaFixToFriendly {
    param([string]$Fix)

    $friendly = $Fix
    $friendly = $friendly -replace '\\prepare\.ps1\s+-Apply', "Click 'Prepare my PC', then try Inspera again"
    $friendly = $friendly -replace '\\diagnose\.ps1', "Click 'Why did Inspera fail?' for details"
    $friendly = $friendly -replace 'Run:\s*', ''
    $friendly = $friendly -replace 'Run\s+', ''
    $friendly = $friendly.Trim()
    return $friendly
}
