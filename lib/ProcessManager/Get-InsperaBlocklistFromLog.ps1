function Get-InsperaBlocklistFromLog {
    param([string]$LogPath)

    $apps = @()
    try {
        $resolved = if ($LogPath) { Get-InsperaLogPath -LogPath $LogPath } else { Get-InsperaLogPath }
        if ($resolved) {
            $lines = Get-Content -Path $resolved -ErrorAction SilentlyContinue
            $apps = Get-InsperaApplicationsFromLog -Lines $lines
        }
    } catch {
        # Ignore log parse errors for blocklist augmentation
    }
    return $apps
}
