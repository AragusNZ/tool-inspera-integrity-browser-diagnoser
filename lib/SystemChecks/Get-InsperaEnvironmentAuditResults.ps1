function Get-InsperaEnvironmentAuditResults {
    return @(
        (Test-InsperaRdpSession),
        (Test-InsperaWslRunning),
        (Test-InsperaVirtualizationFeatures)
    )
}
