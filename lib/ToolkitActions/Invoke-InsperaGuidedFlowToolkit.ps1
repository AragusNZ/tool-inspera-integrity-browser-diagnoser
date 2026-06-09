function Invoke-InsperaGuidedFlowToolkit {
    param(
        [string]$LogPath,
        [string]$InsperaUrl,
        [switch]$Proctored,
        [int]$MaxDisplays = 1
    )

    $sections = [System.Collections.Generic.List[object]]::new()
    $totalIssues = 0

    $prepare = Invoke-InsperaPrepareToolkit -Apply -LogPath $LogPath -InsperaUrl $InsperaUrl -Proctored:$Proctored -MaxDisplays $MaxDisplays
    $sections.Add((New-InsperaToolkitSection -Heading 'Step 1: Prepare my PC' -Level $prepare.Status -Lines @($prepare.Summary)))
    foreach ($s in $prepare.Sections) {
        $sections.Add($s)
    }
    if ($prepare.Status -ne 'ok') { $totalIssues++ }

    $preflight = Invoke-InsperaPreflightToolkit -LogPath $LogPath -InsperaUrl $InsperaUrl -Proctored:$Proctored `
        -MaxDisplays $MaxDisplays -SkipEnvironmentAudit -SkipSystemChecks -SkipDiagnosis
    $sections.Add((New-InsperaToolkitSection -Heading 'Step 2: Readiness check' -Level $preflight.Status -Lines @($preflight.Summary)))
    foreach ($s in $preflight.Sections) {
        if ($s.Level -ne 'pass') {
            $sections.Add($s)
        }
    }

    $sections.Add((New-InsperaToolkitSection -Heading 'Step 3: Before you launch Inspera' -Level 'info' -Lines @(Get-InsperaExamReminders -Context 'Guided')))

    if ($preflight.ExitCode -ne 0) { $totalIssues += $preflight.ExitCode }

    $summary = if ($totalIssues -eq 0) {
        'All recommended steps complete. You can launch Inspera now.'
    } else {
        'Some issues remain. Review the sections below before launching Inspera.'
    }

    return (New-InsperaToolkitResult -Status $(if ($totalIssues -eq 0) { 'ok' } else { 'issues' }) `
        -Title 'Recommended steps' -Summary $summary -Sections @($sections) -ExitCode $(if ($totalIssues -gt 0) { 1 } else { 0 }))
}
