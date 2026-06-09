function Resolve-InsperaToolkitUrl {
    param(
        [string]$LogPath,
        [string]$InsperaUrl
    )

    if ($InsperaUrl -and $InsperaUrl -ne 'https://www.inspera.com') {
        return $InsperaUrl
    }

    $config = Get-InsperaConfig
    $baseUrl = if ($config.insperaUrl) { $config.insperaUrl } else { 'https://www.inspera.com' }

    if ($LogPath) {
        try {
            $parseResult = Parse-InsperaLog -LogPath $LogPath
            if ($parseResult.Metadata.Tenant) {
                $tenant = $parseResult.Metadata.Tenant.Trim()
                if ($tenant -notmatch '^https?://') {
                    return "https://$tenant"
                }
                return $tenant
            }
        } catch {
            # Fall back to config URL
        }
    }

    return $baseUrl
}
