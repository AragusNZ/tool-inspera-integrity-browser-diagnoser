function Convert-InsperaCanonicalPath {
    param([string]$Path)

    if ($Path -match '^Microsoft\.PowerShell\.Core\\FileSystem::(.+)$') {
        $Path = $Matches[1]
    }
    return [System.IO.Path]::GetFullPath($Path)
}
