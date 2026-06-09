function Select-InsperaPrimaryFailure {
    param([array]$Failures)

    if (-not $Failures -or $Failures.Count -eq 0) {
        return $null
    }

    $known = @($Failures | Where-Object { $_.Key -ne 'unknown' })
    if ($known.Count -eq 0) {
        return $Failures | Select-Object -Last 1
    }

    $errors = @($known | Where-Object { $_.Level -match '^(?i)(ERROR|ERR|FATAL)$' })
    $pool = if ($errors.Count -gt 0) { $errors } else { $known }

    $ranked = $pool | Sort-Object `
        @{ Expression = { $_.Priority }; Descending = $true }, `
        @{ Expression = { $_.LineNumber }; Descending = $true }
    return $ranked | Select-Object -First 1
}
