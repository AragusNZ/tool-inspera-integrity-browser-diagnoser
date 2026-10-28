#Requires -Version 5.1
# Pester tests for blocklist matching

BeforeAll {
    $script:Root = Split-Path $PSScriptRoot -Parent
    $script:Fixtures = Join-Path $PSScriptRoot 'fixtures'
    . (Join-Path $script:Root 'lib\LogParser.ps1')
    . (Join-Path $script:Root 'lib\ProcessManager.ps1')
}

Describe 'Get-InsperaBlocklistEntries' {
    It 'Loads default blocklist' {
        $entries = Get-InsperaBlocklistEntries -LogPath ''
        $entries.Count | Should -BeGreaterThan 10
        @($entries | Where-Object { $_.Name -eq 'Discord.exe' }).Count | Should -Be 1
        @($entries | Where-Object { $_.Name -eq 'desktopextension.exe' -and $_.Source -eq 'default' }).Count | Should -Be 1
        @($entries | Where-Object { $_.Name -eq 'remoting_host.exe' }).Count | Should -Be 1
    }

    It 'Has no duplicate process names' {
        $names = (Get-InsperaDefaultBlocklist).processes | ForEach-Object { $_.name.ToLower() }
        @($names | Group-Object | Where-Object { $_.Count -gt 1 }).Count | Should -Be 0
    }

    It 'Augments blocklist from log applications' {
        $log = Join-Path $fixtures 'failed-to-close-apps.log'
        $entries = Get-InsperaBlocklistEntries -LogPath $log
        @($entries | Where-Object { $_.Source -eq 'log' }).Count | Should -BeGreaterThan 0
        @($entries | Where-Object { $_.Name -eq 'Overwolf.exe' -and $_.Source -eq 'log' }).Count | Should -Be 1
        @($entries | Where-Object { $_.Name -eq 'desktopextension.exe' }).Count | Should -Be 1
    }
}

Describe 'Invoke-InsperaProcessCleanup' {
    It 'Dry-run does not kill processes' {
        $results = Invoke-InsperaProcessCleanup -Apply:$false
        foreach ($r in $results) {
            $r.Action | Should -Be 'would-kill'
            $r.Success | Should -Be $true
        }
    }
}
