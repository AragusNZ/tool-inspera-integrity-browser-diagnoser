function Add-InsperaOutputLine {
    param(
        [string]$Message,
        [string]$Level = 'info'
    )

    if ($script:InsperaCaptureOutput -and $script:InsperaOutputSink) {
        $script:InsperaOutputSink.Add([PSCustomObject]@{
            Message = $Message
            Level = $Level
        })
    }
}
