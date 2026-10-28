function Test-InsperaVirtualizationFeatures {
    $result = @{
        Name = 'Virtualization features'
        Passed = $true
        Message = 'Hyper-V and Virtual Machine Platform are off'
        Details = @{}
        Warnings = @()
    }

    try {
        # Win32_OptionalFeature works without admin (Get-WindowsOptionalFeature does not); InstallState 1 = enabled
        $features = @(Get-CimInstance -ClassName Win32_OptionalFeature `
            -Filter "Name='Microsoft-Hyper-V-All' OR Name='Microsoft-Hyper-V' OR Name='VirtualMachinePlatform'" -ErrorAction Stop |
            Where-Object { $_.InstallState -eq 1 })
        $labels = @($features | ForEach-Object { if ($_.Name -eq 'VirtualMachinePlatform') { 'Virtual Machine Platform' } else { 'Hyper-V' } } | Select-Object -Unique)
        $result.Details.Enabled = $labels

        if ($labels.Count -gt 0) {
            $result.Warnings += "$($labels -join ' and ') enabled  - if Inspera shows an Environment error, turn these off in Windows Features and restart"
            $result.Message = ($result.Warnings -join '; ')
        }
    } catch {
        $result.Message = 'Virtualization feature check skipped'
    }

    return $result
}
