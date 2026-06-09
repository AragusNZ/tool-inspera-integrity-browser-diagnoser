function Test-InsperaKeyboardLanguage {
    $result = @{
        Name = 'Keyboard language'
        Passed = $true
        Message = ''
        Details = @{}
    }

    try {
        $languages = Get-WinUserLanguageList -ErrorAction Stop
        $tips = @($languages | ForEach-Object { $_.InputMethodTips })
        $result.Details.Languages = $tips
        $result.Message = "Active: $($tips -join ', ')  - verify with your institution's approved list"
    } catch {
        $result.Message = "Could not read keyboard layout: $($_.Exception.Message)"
    }

    return $result
}
