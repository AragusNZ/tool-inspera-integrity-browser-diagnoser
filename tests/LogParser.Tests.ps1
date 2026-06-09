#Requires -Version 5.1
# Pester tests for Inspera log parser
# Run on Windows: Invoke-Pester -Path .\tests\LogParser.Tests.ps1

BeforeAll {
    $script:Root = Split-Path $PSScriptRoot -Parent
    $script:Fixtures = Join-Path $PSScriptRoot 'fixtures'
    . (Join-Path $script:Root 'lib\LogParser.ps1')
}

Describe 'Parse-InsperaLog' {
    It 'Detects Environment - failure from simple fixture' {
        $log = Join-Path $fixtures 'environment-failure.log'
        $result = Parse-InsperaLog -LogPath $log
        $result.Found | Should -Be $true
        $result.PrimaryFailure.Key | Should -Be 'Environment - failure'
        $result.Applications | Should -Contain 'Discord.exe'
        $result.Applications | Should -Contain 'obs64.exe'
    }

    It 'Parses electron-log format with FortKnox context' {
        $log = Join-Path $fixtures 'electron-log-system-check.log'
        $result = Parse-InsperaLog -LogPath $log
        $result.PrimaryFailure.Key | Should -Be 'Environment - failure'
        $result.FailureDetails.Count | Should -BeGreaterThan 0
        @($result.SystemChecks | Where-Object { $_.Type -eq 'pass' }).Count | Should -BeGreaterThan 3
    }

    It 'Parses structured module format and prefers ERROR over WARN' {
        $log = Join-Path $fixtures 'structured-module-check.log'
        $result = Parse-InsperaLog -LogPath $log
        $result.PrimaryFailure.Key | Should -Be 'Process blocklist - failure'
    }

    It 'Detects failed-to-close with JSON process array' {
        $log = Join-Path $fixtures 'failed-to-close-apps.log'
        $result = Parse-InsperaLog -LogPath $log
        $result.PrimaryFailure.Key | Should -Be 'failed to close'
        $result.Applications | Should -Contain 'desktopextension.exe'
        $result.Applications | Should -Contain 'Discord.exe'
    }

    It 'Detects Clock accuracy - failure from JSON log' {
        $log = Join-Path $fixtures 'clock-failure.log'
        $result = Parse-InsperaLog -LogPath $log
        $result.PrimaryFailure.Key | Should -Be 'Clock accuracy - failure'
    }

    It 'Detects multiple hardware failures from JSON module log' {
        $log = Join-Path $fixtures 'memory-screens-power.log'
        $result = Parse-InsperaLog -LogPath $log
        $result.PrimaryFailure.Key | Should -Be 'Memory Check - failure'
        @($result.Failures | Where-Object { $_.Key -eq 'Number of screens - failure' }).Count | Should -BeGreaterThan 0
        @($result.Failures | Where-Object { $_.Key -eq 'Power state - failure' }).Count | Should -BeGreaterThan 0
    }

    It 'Detects proctoring screen capture and webcam errors' {
        $log = Join-Path $fixtures 'screen-capture-proctoring.log'
        $result = Parse-InsperaLog -LogPath $log
        $result.PrimaryFailure.Key | Should -Be 'Cannot upload files'
        @($result.Failures | Where-Object { $_.Key -eq 'Screen Capture' }).Count | Should -BeGreaterThan 0
        @($result.Failures | Where-Object { $_.Key -eq 'Webcam' }).Count | Should -BeGreaterThan 0
        $result.Applications | Should -Contain 'SnippingTool.exe'
    }

    It 'Detects Check "Environment" failed lifecycle syntax' {
        $log = Join-Path $fixtures 'full-system-check-pass-then-fail.log'
        $result = Parse-InsperaLog -LogPath $log
        $result.PrimaryFailure.Key | Should -Be 'Environment - failure'
        @($result.SystemChecks | Where-Object { $_.Type -eq 'pass' }).Count | Should -BeGreaterThan 5
    }

    It 'Detects Process blocklist - failure' {
        $log = Join-Path $fixtures 'blocklist-failure.log'
        $result = Parse-InsperaLog -LogPath $log
        $result.PrimaryFailure.Key | Should -Be 'Process blocklist - failure'
    }

    It 'Detects desktop changed runtime failure' {
        $log = Join-Path $fixtures 'desktop-changed.log'
        $result = Parse-InsperaLog -LogPath $log
        $result.PrimaryFailure.Key | Should -Be 'desktop changed'
    }

    It 'Returns Found=false when log missing' {
        $result = Parse-InsperaLog -LogPath 'C:\nonexistent\inspera-launcher-0.log'
        $result.Found | Should -Be $false
    }

    It 'Parses real IIB Go launcher log (Auckland / tcase)' {
        $log = Join-Path $fixtures 'real-auckland-1781002029.log'
        $result = Parse-InsperaLog -LogPath $log
        $result.Found | Should -Be $true
        $result.PrimaryFailure.Key | Should -Be 'iceworm failure'
        $result.Metadata.Version | Should -Be '1.16.3'
        $result.Metadata.SessionId | Should -Be '1781002029'
        $result.Metadata.Tenant | Should -Be 'auckland.inspera.com'
        @($result.Failures | Where-Object { $_.Key -eq 'UI runtime error' }).Count | Should -BeGreaterThan 0
        @($result.Failures | Where-Object { $_.Key -eq 'system check aborted' }).Count | Should -BeGreaterThan 0
        @($result.SystemChecks | Where-Object { $_.Check -eq 'iceworm' -and $_.Type -eq 'fail' }).Count | Should -Be 1
    }
}

Describe 'Parse-InsperaLogLine' {
    It 'Parses electron-log bracket format' {
        $parsed = Parse-InsperaLogLine -Line '[2026-03-15 09:12:34.123] [error] Environment - failure'
        $parsed.Level | Should -Be 'error'
        $parsed.Message | Should -Be 'Environment - failure'
        $parsed.Timestamp | Should -Not -BeNullOrEmpty
    }

    It 'Parses IIB Go launcher timestamp format' {
        $parsed = Parse-InsperaLogLine -Line '2026/06/09 22:47:09 launching Inspera Integrity Browser v1.16.3'
        $parsed.Timestamp | Should -Be '2026/06/09 22:47:09'
        $parsed.Message | Should -Match 'launching Inspera'
    }

    It 'Parses structured module format' {
        $parsed = Parse-InsperaLogLine -Line '2026-03-15 09:12:01.005 [01] - INFO: [SystemCheck] Running check'
        $parsed.Level | Should -Be 'INFO'
        $parsed.Module | Should -Be 'SystemCheck'
    }
}

Describe 'Get-InsperaFailurePatterns' {
    It 'Includes all major IIB check names' {
        $patterns = Get-InsperaFailurePatterns
        $keys = $patterns | ForEach-Object { $_.Key }
        $keys | Should -Contain 'Environment - failure'
        $keys | Should -Contain 'Clock accuracy - failure'
        $keys | Should -Contain 'CPU features - failure'
        $keys | Should -Contain 'failed to close'
        $keys | Should -Contain 'Full disk access'
    }
}

Describe 'Get-InsperaConfig' {
    It 'Loads logDirectories from config.json' {
        $config = Get-InsperaConfig
        $config.logDirectories.Count | Should -BeGreaterThan 0
        $config.fallbackToUserTemp | Should -Be $true
    }

    It 'Resolves %USERNAME% placeholder in paths' {
        $resolved = Resolve-InsperaConfigPath -Path 'C:\Users\%USERNAME%\AppData\Local\Temp'
        $resolved | Should -Be "C:\Users\$env:USERNAME\AppData\Local\Temp"
    }
}

Describe 'Get-InsperaLogSearchDirectories' {
    It 'Includes configured and fallback directories' {
        $config = Get-InsperaConfig
        $dirs = Get-InsperaLogSearchDirectories
        $dirs.Count | Should -BeGreaterThan 0
        foreach ($entry in $config.logDirectories) {
            $resolved = Resolve-InsperaConfigPath -Path $entry
            $dirs | Should -Contain $resolved
        }
        if ($config.fallbackToUserTemp) {
            $userTemp = [System.IO.Path]::GetTempPath().TrimEnd('\')
            $dirs | Should -Contain $userTemp
        }
    }
}

Describe 'Get-InsperaLogPath' {
    It 'Picks highest numeric suffix' {
        $tempDir = Join-Path $TestDrive 'logs'
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        Set-Content (Join-Path $tempDir 'inspera-launcher-100.log') 'old'
        Set-Content (Join-Path $tempDir 'inspera-launcher-999.log') 'new'

        $path = Get-InsperaLogPath -LogPath (Join-Path $tempDir 'inspera-launcher-999.log')
        $path | Should -Match '999'
    }
}
