function Test-InsperaVirtualizationFeatures {
    $result = @{
        Name = 'Virtualization features'
        Passed = $true
        Message = 'Informational only'
        Details = @{}
        Warnings = @()
    }

    try {
        $vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue
        if ($vmPlatform -and $vmPlatform.State -eq 'Enabled') {
            $result.Warnings += 'Virtual Machine Platform is enabled (informational)'
        }

        $hyperV = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue
        if ($hyperV -and $hyperV.State -eq 'Enabled') {
            $result.Warnings += 'Hyper-V is enabled (informational)'
        }
    } catch {
        $result.Message = 'Virtualization feature check skipped (may need admin)'
    }

    if ($result.Warnings.Count -gt 0) {
        $result.Message = ($result.Warnings -join '; ')
    }

    return $result
}
