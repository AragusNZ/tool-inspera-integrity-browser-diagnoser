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

    It 'inspera-preflight.ps1 runs read-only against fixture' {
        $log = Join-Path $fixtures 'environment-failure.log'
        { & (Join-Path $root 'inspera-preflight.ps1') -LogPath $log } | Should -Not -Throw
    }

    It 'prepare.ps1 dry-run completes' {
        $log = Join-Path $fixtures 'environment-failure.log'
        { & (Join-Path $root 'prepare.ps1') -LogPath $log } | Should -Not -Throw
    }
}
