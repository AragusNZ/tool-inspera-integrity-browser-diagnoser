function Invoke-InsperaDiagnoseToolkit {
    param(
        [string]$LogPath,
        [string]$InsperaUrl,
        [switch]$VerboseReport
    )

    $resolvedLogPath = if ($LogPath) { Get-InsperaLogPath -LogPath $LogPath } else { Get-InsperaLogPath }
    $effectiveUrl = Resolve-InsperaToolkitUrl -LogPath $resolvedLogPath -InsperaUrl $InsperaUrl

    $catalog = Get-InsperaErrorCatalog
    $parseResult = Parse-InsperaLog -LogPath $resolvedLogPath -Verbose:$VerboseReport
    $liveMatches = Get-InsperaRunningBlocklistMatches -LogPath $resolvedLogPath
    $sections = Get-InsperaDiagnosisSections -ParseResult $parseResult -ErrorCatalog $catalog `
        -LiveBlocklistMatches $liveMatches -InsperaUrl $effectiveUrl -LogPath $resolvedLogPath -VerboseReport:$VerboseReport

    if (-not $parseResult.Found) {
        return (New-InsperaToolkitResult -Status 'error' -Title 'Why did Inspera fail?' `
            -Summary 'No Inspera log file found.' -Sections $sections -ExitCode 2)
    }

    if ($parseResult.PrimaryFailure) {
        return (New-InsperaToolkitResult -Status 'issues' -Title 'Why did Inspera fail?' `
            -Summary 'A problem was found in your last Inspera session. See fixes below.' -Sections $sections -ExitCode 1)
    }

    return (New-InsperaToolkitResult -Status 'ok' -Title 'Why did Inspera fail?' `
        -Summary 'No failure detected in the latest log.' -Sections $sections -ExitCode 0)
}
