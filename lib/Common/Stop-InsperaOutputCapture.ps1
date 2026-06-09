function Stop-InsperaOutputCapture {
    $script:InsperaCaptureOutput = $false
    $captured = if ($script:InsperaOutputSink) { @($script:InsperaOutputSink) } else { @() }
    $script:InsperaOutputSink = $null
    return $captured
}
