function Test-InsperaWebcam {
    $result = @{
        Name = 'Webcam (proctored)'
        Passed = $false
        Message = ''
        Details = @{}
        Warnings = @()
    }

    try {
        $cameras = @(Get-CimInstance -ClassName Win32_PnPEntity -Filter "PNPClass='Camera' OR PNPClass='Image'" -ErrorAction Stop |
            Where-Object { $_.Status -eq 'OK' })
        $result.Details.Cameras = @($cameras | ForEach-Object { $_.Name })

        if ($cameras.Count -eq 0) {
            $result.Message = 'No webcam detected  - proctored exams need a working camera (check privacy shutter and Device Manager)'
            return $result
        }

        $result.Passed = $true
        $result.Message = "$($cameras.Count) camera(s): $(($cameras | ForEach-Object { $_.Name }) -join ', ')"

        if ($cameras | Where-Object { $_.Name -match 'LifeCam HD-3000' }) {
            $result.Warnings += 'Microsoft LifeCam HD-3000 detected  - known to fail Inspera''s camera check, use a different webcam'
        }
        if ($cameras.Count -gt 1) {
            $result.Warnings += "$($cameras.Count) cameras detected  - if Inspera picks the wrong one, select it manually in Inspera or disable the other in Device Manager"
        }
    } catch {
        $result.Passed = $true
        $result.Message = "Webcam check skipped: $($_.Exception.Message)"
    }

    return $result
}
