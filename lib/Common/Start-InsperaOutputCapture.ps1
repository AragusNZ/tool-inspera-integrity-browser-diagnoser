function Start-InsperaOutputCapture {
    $script:InsperaOutputSink = [System.Collections.Generic.List[object]]::new()
    $script:InsperaCaptureOutput = $true
}
