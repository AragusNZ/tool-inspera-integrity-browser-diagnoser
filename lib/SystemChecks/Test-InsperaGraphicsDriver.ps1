function Test-InsperaGraphicsDriver {
    # IIB's UI (Fyne/GLFW) needs an OpenGL 2.0 capable driver; the basic adapter has none.
    $result = @{
        Name = 'Graphics driver'
        Passed = $false
        Message = ''
        Details = @{}
    }

    try {
        $controllers = @(Get-CimInstance -ClassName Win32_VideoController -ErrorAction Stop)
        $result.Details.Adapters = @($controllers | ForEach-Object { "$($_.Name) ($($_.DriverVersion))" })

        $basic = @($controllers | Where-Object { $_.Name -match 'Microsoft Basic Display|Standard VGA' })
        $faulty = @($controllers | Where-Object { $_.Status -and $_.Status -ne 'OK' })

        if ($controllers.Count -eq 0 -or $basic.Count -eq $controllers.Count) {
            $result.Message = 'No real graphics driver installed (Microsoft Basic Display Adapter)  - update graphics drivers or Inspera may crash'
        } elseif ($faulty.Count -gt 0) {
            $result.Message = "Graphics adapter reports status '$($faulty[0].Status)'  - update or reinstall graphics drivers"
        } else {
            $result.Passed = $true
            $result.Message = ($controllers | Where-Object { $_.Name -notmatch 'Microsoft Basic Display' } | Select-Object -First 1).Name
        }
    } catch {
        $result.Passed = $true
        $result.Message = "Graphics driver check skipped: $($_.Exception.Message)"
    }

    return $result
}
