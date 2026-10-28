function Get-InsperaEnvironmentAuditResults {
    return @(
        (Test-InsperaRdpSession),
        (Test-InsperaVirtualMachine),
        (Test-InsperaWslRunning),
        (Test-InsperaVirtualizationFeatures)
    )
}
