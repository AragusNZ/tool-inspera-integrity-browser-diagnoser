#Requires -Version 5.1
# Smoke tests for user-facing entry scripts

BeforeAll {
    $script:Root = Split-Path $PSScriptRoot -Parent
    $script:Fixtures = Join-Path $PSScriptRoot 'fixtures'
}

Describe 'Entry script smoke tests' {
    It 'diagnose.ps1 reports primary failure from fixture log' {
        $log = Join-Path $fixtures 'environment-failure.log'
        & (Join-Path $root 'diagnose.ps1') -LogPath $log
        $LASTEXITCODE | Should -Be 1
    }

    It 'inspera-preflight.ps1 returns exit code 1 for fixture with failure' {
        $log = Join-Path $fixtures 'environment-failure.log'
        & (Join-Path $root 'inspera-preflight.ps1') -LogPath $log
        $LASTEXITCODE | Should -Be 1
    }

    It 'prepare.ps1 dry-run completes with exit code 0 or 1' {
        $log = Join-Path $fixtures 'environment-failure.log'
        & (Join-Path $root 'prepare.ps1') -LogPath $log | Out-Null
        $LASTEXITCODE | Should -BeIn 0, 1
    }
}
