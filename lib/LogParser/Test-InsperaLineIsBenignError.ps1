function Test-InsperaLineIsBenignError {
    param([string]$Line)

    return $Line -match 'no error|without error|0 error|errorCount.:0|errors.:0|"error":null|error.:false'
}
