function Invoke-InsperaSystemChecks {
    param(
        [string]$InsperaUrl = 'https://www.inspera.com',
        [switch]$Proctored,
        [int]$MaxDisplays = 1
    )

    # Remote session / VM / WSL / Hyper-V live in Get-InsperaEnvironmentAuditResults (Environment section)
    $checks = [System.Collections.Generic.List[object]]::new()

    $checks.Add((Test-InsperaOsSupport))
    $checks.Add((Test-InsperaIibVersion))
    $checks.Add((Test-InsperaIibRunning))
    $checks.Add((Test-InsperaClockSkew))
    $checks.Add((Test-InsperaDisplayCount -MaxDisplays $MaxDisplays))
    $checks.Add((Test-InsperaPowerState))
    $checks.Add((Test-InsperaFreeMemory))
    $checks.Add((Test-InsperaDiskSpace -Proctored:$Proctored))
    $checks.Add((Test-InsperaSse42))
    $checks.Add((Test-InsperaGraphicsDriver))
    $checks.Add((Test-InsperaNetwork -InsperaUrl $InsperaUrl))
    $checks.Add((Test-InsperaTempWritable))
    $checks.Add((Test-InsperaKeyboardLanguage))
    $checks.Add((Test-InsperaAdminRights))

    if ($Proctored) {
        $checks.Add((Test-InsperaWebcam))
    }

    return @($checks)
}
