function Test-InsperaTempWritable {
    $result = @{
        Name = 'Temp folder writable'
        Passed = $false
        Message = ''
        Details = @{}
    }

    try {
        $temp = [System.IO.Path]::GetTempPath()
        $testFile = Join-Path $temp "inspera-preflight-test-$([Guid]::NewGuid()).tmp"
        Set-Content -Path $testFile -Value 'test' -ErrorAction Stop
        Remove-Item -Path $testFile -Force -ErrorAction Stop
        $result.Passed = $true
        $result.Message = "Writable: $temp"
        $result.Details.Path = $temp
    } catch {
        $result.Message = "Temp folder not writable: $($_.Exception.Message)"
    }

    return $result
}
