function Get-InsperaConfig {
    $defaults = [PSCustomObject]@{
        logDirectories = @()
        fallbackToUserTemp = $true
        insperaUrl = 'https://www.inspera.com'
        minimumIibVersion = '1.15.4'
        approvedKeyboardLanguages = @()
    }

    $configPath = Get-InsperaConfigPath
    if (-not (Test-Path $configPath)) {
        return $defaults
    }

    try {
        $raw = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        return [PSCustomObject]@{
            logDirectories = @($raw.logDirectories)
            fallbackToUserTemp = if ($null -ne $raw.fallbackToUserTemp) { [bool]$raw.fallbackToUserTemp } else { $true }
            insperaUrl = if ($raw.insperaUrl) { $raw.insperaUrl } else { 'https://www.inspera.com' }
            minimumIibVersion = if ($raw.minimumIibVersion) { [string]$raw.minimumIibVersion } else { '1.15.4' }
            approvedKeyboardLanguages = @($raw.approvedKeyboardLanguages | Where-Object { $_ })
        }
    } catch {
        return $defaults
    }
}
