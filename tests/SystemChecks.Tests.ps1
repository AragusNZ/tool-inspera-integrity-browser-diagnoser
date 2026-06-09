#Requires -Version 5.1
# Pester tests for system checks and targeted diagnostics

BeforeAll {
    $script:Root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $script:Root 'lib\LogParser.ps1')
    . (Join-Path $script:Root 'lib\SystemChecks.ps1')
}

Describe 'Get-InsperaEnvironmentAuditResults' {
    It 'Returns RDP, WSL, and virtualization checks with expected structure' {
        $results = Get-InsperaEnvironmentAuditResults
        $names = $results | ForEach-Object { $_.Name }
        $names | Should -Contain 'Remote session'
        $names | Should -Contain 'WSL status'
        $names | Should -Contain 'Virtualization features'
        foreach ($check in $results) {
            $check.Name | Should -Not -BeNullOrEmpty
            $check.Keys | Should -Contain 'Passed'
            $check.Keys | Should -Contain 'Message'
        }
    }
}

Describe 'Invoke-InsperaTargetedChecks' {
    It 'Maps Environment failure to environment audit checks' {
        $checks = Invoke-InsperaTargetedChecks -FailureKey 'Environment - failure'
        @($checks | Where-Object { $_.Name -eq 'Remote session' }).Count | Should -Be 1
    }

    It 'Maps Clock failure to clock skew check' {
        $checks = Invoke-InsperaTargetedChecks -FailureKey 'Clock accuracy - failure'
        @($checks | Where-Object { $_.Name -eq 'Clock accuracy' }).Count | Should -Be 1
    }

    It 'Maps Connection failure to network and quality checks' {
        $checks = Invoke-InsperaTargetedChecks -FailureKey 'Connection quality - failure'
        @($checks | Where-Object { $_.Name -eq 'Network connectivity' }).Count | Should -Be 1
        @($checks | Where-Object { $_.Name -eq 'Connection quality' }).Count | Should -Be 1
    }

    It 'Returns empty for unknown failure' {
        $checks = Invoke-InsperaTargetedChecks -FailureKey 'totally unknown'
        $checks.Count | Should -Be 0
    }
}
