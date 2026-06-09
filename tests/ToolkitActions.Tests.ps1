#Requires -Version 5.1
# Pester tests for toolkit orchestration

BeforeAll {
    $script:Root = Split-Path $PSScriptRoot -Parent
    $script:Fixtures = Join-Path $PSScriptRoot 'fixtures'
    $InsperaToolkitRoot = $script:Root
    . (Join-Path $script:Root 'lib\Bootstrap-InsperaToolkit.ps1')
}

Describe 'Get-InsperaDiagnosisSections' {
    It 'Produces failure section with catalog entry for environment failure' {
        $log = Join-Path $fixtures 'electron-log-system-check.log'
        $parseResult = Parse-InsperaLog -LogPath $log
        $catalog = Get-InsperaErrorCatalog
        $sections = Get-InsperaDiagnosisSections -ParseResult $parseResult -ErrorCatalog $catalog `
            -LiveBlocklistMatches @() -InsperaUrl 'https://www.inspera.com' -LogPath $log

        @($sections | Where-Object { $_.Heading -eq 'Why Inspera failed' }).Count | Should -Be 1
        $failSection = $sections | Where-Object { $_.Heading -eq 'Why Inspera failed' } | Select-Object -First 1
        ($failSection.Lines -join "`n") | Should -Match 'Environment'
    }

    It 'Handles missing log gracefully' {
        $parseResult = @{
            Found = $false; LogPath = $null; PrimaryFailure = $null
            Failures = @(); Applications = @(); SystemChecks = @()
            FailureDetails = @(); Metadata = @{}
        }
        $sections = Get-InsperaDiagnosisSections -ParseResult $parseResult -ErrorCatalog @{} `
            -LiveBlocklistMatches @() -InsperaUrl 'https://www.inspera.com' -LogPath $null

        @($sections | Where-Object { $_.Heading -eq 'No log found' }).Count | Should -Be 1
    }
}

Describe 'Invoke-InsperaDiagnoseToolkit' {
    It 'Returns exit code 1 when fixture log has a primary failure' {
        $log = Join-Path $fixtures 'environment-failure.log'
        $result = Invoke-InsperaDiagnoseToolkit -LogPath $log
        $result.ExitCode | Should -Be 1
        $result.Title | Should -Be 'Why did Inspera fail?'
        @($result.Sections | Where-Object { $_.Heading -eq 'Why Inspera failed' }).Count | Should -Be 1
    }

    It 'Returns exit code 2 when log is missing' {
        $missing = Join-Path $TestDrive 'no-such-inspera.log'
        $result = Invoke-InsperaDiagnoseToolkit -LogPath $missing
        $result.ExitCode | Should -Be 2
        @($result.Sections | Where-Object { $_.Heading -eq 'No log found' }).Count | Should -Be 1
    }
}

Describe 'Invoke-InsperaPrepareToolkit' {
    It 'Dry-run includes interfering apps and system readiness sections' {
        $log = Join-Path $fixtures 'environment-failure.log'
        $result = Invoke-InsperaPrepareToolkit -LogPath $log
        $headings = $result.Sections | ForEach-Object { $_.Heading }
        $headings | Should -Contain 'Interfering apps'
        $headings | Should -Contain 'Environment'
        $headings | Should -Contain 'System readiness'
        $headings | Should -Contain 'Before you start Inspera'
    }
}

Describe 'Invoke-InsperaPreflightToolkit' {
    It 'Includes readiness sections for fixture log' {
        $log = Join-Path $fixtures 'environment-failure.log'
        $result = Invoke-InsperaPreflightToolkit -LogPath $log
        $headings = $result.Sections | ForEach-Object { $_.Heading }
        $headings | Should -Contain 'Environment'
        $headings | Should -Contain 'System readiness'
        $headings | Should -Contain 'Interfering apps'
    }

    It 'Skip flags omit repeated sections for guided follow-up' {
        $log = Join-Path $fixtures 'environment-failure.log'
        $result = Invoke-InsperaPreflightToolkit -LogPath $log -SkipEnvironmentAudit -SkipSystemChecks -SkipDiagnosis
        $headings = $result.Sections | ForEach-Object { $_.Heading }
        $headings | Should -Contain 'Interfering apps'
        $headings | Should -Not -Contain 'Environment'
        $headings | Should -Not -Contain 'System readiness'
        $headings | Should -Not -Contain 'Why Inspera failed'
    }
}

Describe 'Invoke-InsperaGuidedFlowToolkit' {
    BeforeEach {
        Mock Invoke-InsperaPrepareToolkit {
            return (New-InsperaToolkitResult -Status 'ok' -Title 'Prepare my PC' `
                -Summary 'Prepare complete - 10/10 system checks passed' -Sections @(
                    (New-InsperaToolkitSection -Heading 'Interfering apps' -Level 'pass' -Lines @('[PASS] No interfering apps running'))
                ) -ExitCode 0)
        }
        Mock Invoke-InsperaPreflightToolkit {
            return (New-InsperaToolkitResult -Status 'ok' -Title 'Am I ready?' `
                -Summary 'Your PC looks ready for Inspera.' -Sections @(
                    (New-InsperaToolkitSection -Heading 'Interfering apps' -Level 'pass' -Lines @('[PASS] No interfering apps running'))
                ) -ExitCode 0)
        }
    }

    It 'Calls prepare with Apply then lightweight preflight' {
        $log = Join-Path $fixtures 'environment-failure.log'
        $result = Invoke-InsperaGuidedFlowToolkit -LogPath $log

        Should -Invoke Invoke-InsperaPrepareToolkit -Times 1 -ParameterFilter { $Apply -eq $true }
        Should -Invoke Invoke-InsperaPreflightToolkit -Times 1 -ParameterFilter {
            $SkipEnvironmentAudit -and $SkipSystemChecks -and $SkipDiagnosis
        }
        $result.Title | Should -Be 'Recommended steps'
        $result.ExitCode | Should -Be 0
        @($result.Sections | Where-Object { $_.Heading -eq 'Step 3: Before you launch Inspera' }).Count | Should -Be 1
    }
}

Describe 'Invoke-InsperaWslShutdown' {
    It 'Skips wsl --shutdown when INSPERA_TEST_MODE is set' {
        $previous = $env:INSPERA_TEST_MODE
        $env:INSPERA_TEST_MODE = '1'
        try {
            $result = Invoke-InsperaWslShutdown -Apply
            $result.Ran | Should -Be $false
            $result.Message | Should -Match 'test mode'
        } finally {
            $env:INSPERA_TEST_MODE = $previous
        }
    }
}
