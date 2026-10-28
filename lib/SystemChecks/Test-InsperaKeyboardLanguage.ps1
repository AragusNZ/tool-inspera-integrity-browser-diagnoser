function Test-InsperaKeyboardLanguage {
    param([string[]]$ApprovedLanguages)

    if ($null -eq $ApprovedLanguages) {
        $ApprovedLanguages = @((Get-InsperaConfig).approvedKeyboardLanguages)
    }
    $ApprovedLanguages = @($ApprovedLanguages | Where-Object { $_ })

    $result = @{
        Name = 'Keyboard language'
        Passed = $true
        Informational = ($ApprovedLanguages.Count -eq 0)
        Message = ''
        Details = @{}
    }

    try {
        $languages = @(Get-WinUserLanguageList -ErrorAction Stop)
        $tags = @($languages | ForEach-Object { $_.LanguageTag })
        $result.Details.Languages = $tags
        $result.Details.Approved = $ApprovedLanguages

        if ($ApprovedLanguages.Count -eq 0) {
            $result.Message = "Active: $($tags -join ', ')  - verify with your institution's approved list"
            return $result
        }

        # 'en' approves every en-* layout; 'en-NZ' approves only that tag
        $matched = @($tags | Where-Object { $tag = $_; $ApprovedLanguages | Where-Object { $tag -ieq $_ -or $tag -ilike "$_-*" } })
        if ($matched.Count -gt 0) {
            $result.Message = "Approved layout active: $($matched -join ', ')"
        } else {
            $result.Passed = $false
            $result.Message = "Active: $($tags -join ', ')  - switch to an approved layout ($($ApprovedLanguages -join ', ')) in Settings > Time & language"
        }
    } catch {
        $result.Informational = $true
        $result.Message = "Could not read keyboard layout: $($_.Exception.Message)"
    }

    return $result
}
