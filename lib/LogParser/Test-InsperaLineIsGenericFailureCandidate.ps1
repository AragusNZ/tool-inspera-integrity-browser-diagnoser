function Test-InsperaLineIsGenericFailureCandidate {
    param(
        [string]$Haystack,
        [string]$Message
    )

    if (Test-InsperaLineIsBenignError -Line $Haystack) {
        return $false
    }
    if ($Message -match '^Fyne error:|^\s+At:') {
        return $false
    }
    if ($Haystack -match '\b(failure|failed)\b') {
        return $true
    }
    if ($Haystack -match '\berror\b' -and $Message -notmatch 'Fyne error') {
        return $true
    }
    return $false
}
