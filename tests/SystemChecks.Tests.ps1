#Requires -Version 5.1
# Pester tests for system checks and targeted diagnostics

BeforeAll {
    $script:Root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $script:Root 'lib\Common.ps1')
    . (Join-Path $script:Root 'lib\LogParser.ps1')
    . (Join-Path $script:Root 'lib\SystemChecks.ps1')
}

Describe 'Convert-InsperaNtpResponse' {
    It 'Decodes big-endian transmit timestamp into UTC' {
        $packet = New-Object byte[] 48
        # seconds 0xE87A9E00 = 3900349952 since 1900 -> mid 2023; fraction 0x80000000 = +0.5s
        $packet[40] = 0xE8; $packet[41] = 0x7A; $packet[42] = 0x9E; $packet[43] = 0x00
        $packet[44] = 0x80
        $dt = Convert-InsperaNtpResponse -Response $packet
        $dt.Kind | Should -Be 'Utc'
        $dt.Year | Should -Be 2023
        $dt.Millisecond | Should -Be 500
    }

    It 'Rejects short packets' {
        { Convert-InsperaNtpResponse -Response (New-Object byte[] 10) } | Should -Throw
    }
}

Describe 'Invoke-InsperaSystemChecks' {
    It 'Returns uniquely named checks with Passed and Message' {
        $checks = Invoke-InsperaSystemChecks -Proctored
        $checks.Count | Should -BeGreaterThan 12
        $names = @($checks | ForEach-Object { $_.Name })
        @($names | Select-Object -Unique).Count | Should -Be $names.Count
        $names | Should -Contain 'Windows version'
        $names | Should -Contain 'Graphics driver'
        $names | Should -Contain 'Disk space (proctored)'
        $names | Should -Contain 'Inspera not already running'
        $names | Should -Contain 'Administrator rights'
        $names | Should -Contain 'Webcam (proctored)'
        foreach ($check in $checks) {
            $check.Keys | Should -Contain 'Passed'
            $check.Message | Should -Not -BeNullOrEmpty
        }
    }

    It 'Omits webcam check unless proctored' {
        $names = @(Invoke-InsperaSystemChecks | ForEach-Object { $_.Name })
        $names | Should -Not -Contain 'Webcam (proctored)'
        $names | Should -Contain 'Disk space'
    }
}

Describe 'Informational checks' {
    It 'Administrator rights is informational and renders as INFO' {
        $check = Test-InsperaAdminRights
        $check.Informational | Should -Be $true
        @(Convert-InsperaCheckToLine -Check $check)[0] | Should -Match '^\[INFO\]'
        Convert-InsperaCheckToLevel -Check $check | Should -Be 'info'
    }

    It 'Keyboard language is informational without an approved list' {
        $check = Test-InsperaKeyboardLanguage -ApprovedLanguages @()
        $check.Informational | Should -Be $true
        $check.Passed | Should -Be $true
    }

    It 'Keyboard language fails when no active layout is approved' {
        $check = Test-InsperaKeyboardLanguage -ApprovedLanguages @('zz-ZZ')
        $check.Informational | Should -Be $false
        $check.Passed | Should -Be $false
    }
}

Describe 'Hardware checks' {
    It 'Windows version passes on a supported 64-bit OS' {
        $check = Test-InsperaOsSupport
        $check.Passed | Should -Be $true
        $check.Details.Architecture | Should -Match '64'
    }

    It 'SSE4.2 check uses a real probe, not the skipped fallback' {
        $check = Test-InsperaSse42
        $check.Message | Should -Not -Match 'skipped'
        $check.Details.Source | Should -Not -BeNullOrEmpty
    }

    It 'Power state reports a PowerLineStatus' {
        $check = Test-InsperaPowerState
        $check.Details.PowerLineStatus | Should -Not -BeNullOrEmpty
    }

    It 'Remote session check does not shell out' {
        $check = Test-InsperaRdpSession
        $check.Message | Should -Not -Match 'skipped'
    }

    It 'Virtual machine check reports manufacturer' {
        $check = Test-InsperaVirtualMachine
        $check.Details.Manufacturer | Should -Not -BeNullOrEmpty
    }
}

Describe 'Get-InsperaEnvironmentAuditResults' {
    It 'Returns RDP, WSL, and virtualization checks with expected structure' {
        $results = Get-InsperaEnvironmentAuditResults
        $names = $results | ForEach-Object { $_.Name }
        $names | Should -Contain 'Remote session'
        $names | Should -Contain 'Virtual machine'
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

    It 'Does not map Process blocklist failure to network checks' {
        $checks = Invoke-InsperaTargetedChecks -FailureKey 'Process blocklist - failure'
        $checks.Count | Should -Be 0
        @($checks | Where-Object { $_.Name -eq 'Network connectivity' }).Count | Should -Be 0
    }

    It 'Maps UI runtime error to graphics driver check' {
        $checks = Invoke-InsperaTargetedChecks -FailureKey 'UI runtime error'
        @($checks | Where-Object { $_.Name -eq 'Graphics driver' }).Count | Should -Be 1
    }

    It 'Probes the connectionCheck URL recorded in the log' {
        $log = Join-Path $script:Root 'tests\fixtures\real-auckland-1781002029.log'
        $checks = Invoke-InsperaTargetedChecks -FailureKey 'iceworm failure' -LogPath $log
        @($checks | Where-Object { $_.Details.Url -match 'connectionCheck\.json' }).Count | Should -Be 1
    }

    It 'Maps IIB already running to the running-process check' {
        $checks = Invoke-InsperaTargetedChecks -FailureKey 'IIB already running'
        @($checks | Where-Object { $_.Name -eq 'Inspera not already running' }).Count | Should -Be 1
    }

    It 'Returns empty for unknown failure' {
        $checks = Invoke-InsperaTargetedChecks -FailureKey 'totally unknown'
        $checks.Count | Should -Be 0
    }
}
