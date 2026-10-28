function Test-InsperaOsSupport {
    $result = @{
        Name = 'Windows version'
        Passed = $false
        Message = ''
        Details = @{}
        Warnings = @()
    }

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $version = [Version]$os.Version
        $result.Details.Caption = $os.Caption
        $result.Details.Version = $os.Version
        $result.Details.Architecture = $os.OSArchitecture
        $result.Details.ProcessorArchitecture = $env:PROCESSOR_ARCHITECTURE

        if ($version.Major -lt 10) {
            $result.Message = "$($os.Caption) is not supported  - Inspera needs Windows 10 or 11 (64-bit)"
            return $result
        }
        if ($os.OSArchitecture -notmatch '64') {
            $result.Message = "$($os.OSArchitecture) Windows is not supported  - Inspera needs 64-bit Windows"
            return $result
        }

        $result.Passed = $true
        $result.Message = "$($os.Caption) ($($os.OSArchitecture))"

        if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
            $result.Warnings += 'ARM-based PC  - Inspera needs IIB version 2.3.0 or newer on ARM'
        }

        $policy = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -ErrorAction SilentlyContinue
        if ($policy -and $policy.SkuPolicyRequired -eq 1) {
            $result.Warnings += 'Windows S mode is on  - Inspera cannot be installed until you switch out of S mode (Settings > System > Activation)'
        }
    } catch {
        $result.Passed = $true
        $result.Message = "Windows version check skipped: $($_.Exception.Message)"
    }

    return $result
}
