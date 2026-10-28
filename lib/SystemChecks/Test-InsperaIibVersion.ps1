function Test-InsperaIibVersion {
    param([string]$MinimumVersion)

    if (-not $MinimumVersion) {
        $MinimumVersion = (Get-InsperaConfig).minimumIibVersion
    }

    $result = @{
        Name = 'IIB installation'
        Passed = $false
        Message = ''
        Details = @{}
        Warnings = @()
    }

    $searchPaths = @(
        "${env:ProgramFiles}\Inspera Integrity Browser",
        "${env:ProgramFiles(x86)}\Inspera Integrity Browser",
        "${env:LocalAppData}\Programs\Inspera Integrity Browser",
        "${env:LocalAppData}\Inspera Integrity Browser"
    )
    $legacyPaths = @(
        "${env:ProgramFiles}\Inspera Exam Portal",
        "${env:ProgramFiles(x86)}\Inspera Exam Portal",
        "${env:ProgramData}\Inspera Exam Portal"
    )

    foreach ($legacy in $legacyPaths) {
        if (Test-Path $legacy) {
            $result.Warnings += "Old 'Inspera Exam Portal' still installed ($legacy)  - uninstall it before installing the current Inspera Integrity Browser"
            break
        }
    }

    foreach ($path in $searchPaths) {
        if (-not (Test-Path $path)) { continue }

        $exe = Get-ChildItem -Path $path -Filter '*.exe' -Recurse -ErrorAction SilentlyContinue |
            Sort-Object { if ($_.Name -ieq 'inspera-launcher.exe') { 0 } else { 1 } } |
            Where-Object { $_.Name -match 'inspera|launcher|IIB' } |
            Select-Object -First 1

        if (-not $exe) {
            $result.Passed = $true
            $result.Message = "Found installation folder: $path"
            $result.Details.Path = $path
            return $result
        }

        $version = $exe.VersionInfo.FileVersion
        $result.Details.Path = $exe.FullName
        $result.Details.Version = $version
        $result.Details.MinimumVersion = $MinimumVersion

        $parsed = $null
        if ($version -and [Version]::TryParse(($version -replace '[^\d.].*$', ''), [ref]$parsed) -and $MinimumVersion -and $parsed -lt [Version]$MinimumVersion) {
            $result.Message = "Installed v$version is older than $MinimumVersion  - uninstall it, then install the latest from your institution's Inspera link"
            return $result
        }

        $result.Passed = $true
        $result.Message = "Found: $($exe.FullName) v$version"
        return $result
    }

    $result.Message = 'Inspera Integrity Browser not found  - install it from your institution''s link (run the installer as administrator)'
    return $result
}
