function Test-InsperaIibVersion {
    $result = @{
        Name = 'IIB installation'
        Passed = $false
        Message = ''
        Details = @{}
    }

    $searchPaths = @(
        "${env:ProgramFiles}\Inspera Integrity Browser",
        "${env:ProgramFiles(x86)}\Inspera Integrity Browser",
        "${env:LocalAppData}\Programs\Inspera Integrity Browser"
    )

    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $exe = Get-ChildItem -Path $path -Filter '*.exe' -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match 'Inspera|inspera|launcher|IIB' } |
                Select-Object -First 1
            if ($exe) {
                $version = $exe.VersionInfo.FileVersion
                $result.Passed = $true
                $result.Message = "Found: $($exe.FullName) v$version"
                $result.Details.Path = $exe.FullName
                $result.Details.Version = $version
                return $result
            }
            $result.Passed = $true
            $result.Message = "Found installation folder: $path"
            $result.Details.Path = $path
            return $result
        }
    }

    $result.Message = 'IIB not found in standard install locations'
    return $result
}
