function Test-InsperaAdminRights {
    $result = @{
        Name = 'Administrator rights'
        Passed = $true
        Informational = $true
        Message = ''
        Details = @{}
    }

    try {
        $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        $result.Details.IsAdmin = $isAdmin
        $result.Message = if ($isAdmin) {
            'Running as administrator'
        } else {
            'Not running as administrator  - fine for most exams; needed to install Inspera and for Strict lockdown exams'
        }
    } catch {
        $result.Message = 'Administrator check skipped'
    }

    return $result
}
