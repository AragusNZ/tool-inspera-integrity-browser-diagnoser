function Get-InsperaCheckKeyFromName {
    param([string]$CheckName)

    $normalized = $CheckName.Trim().Trim('"').Trim("'")
    $map = @{
        'Login configuration' = 'After completion - failed'
        'Environment' = 'Environment - failure'
        'Process blocklist' = 'Process blocklist - failure'
        'Connection quality' = 'Connection quality - failure'
        'Clock accuracy' = 'Clock accuracy - failure'
        'Number of screens' = 'Number of screens - failure'
        'Power state' = 'Power state - failure'
        'Memory Check' = 'Memory Check - failure'
        'CPU features' = 'CPU features - failure'
        'App version' = 'App version - failure'
        'App location' = 'App location - failure'
        'Screen Capture' = 'Screen Capture'
        'Webcam Capture' = 'Webcam'
        'File upload' = 'Cannot upload files'
        'Available disk space' = 'Cannot upload files'
    }

    if ($map.ContainsKey($normalized)) {
        return $map[$normalized]
    }
    return $null
}
