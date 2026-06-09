function New-InsperaToolkitResult {
    param(
        [string]$Status = 'ok',
        [string]$Title,
        [string]$Summary = '',
        [array]$Sections = @(),
        [int]$ExitCode = 0
    )

    return [PSCustomObject]@{
        Status = $Status
        Title = $Title
        Summary = $Summary
        Sections = @($Sections)
        ExitCode = $ExitCode
    }
}
