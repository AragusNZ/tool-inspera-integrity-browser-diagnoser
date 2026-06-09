#Requires -Version 5.1
# Pester tests for committed configuration

BeforeAll {
    $script:Root = Split-Path $PSScriptRoot -Parent
    . (Join-Path $script:Root 'lib\LogParser.ps1')
}

Describe 'Committed config.json' {
    It 'Uses placeholder paths instead of hardcoded usernames' {
        $configPath = Join-Path $script:Root 'data\config.json'
        $raw = Get-Content -Path $configPath -Raw
        $raw | Should -Not -Match '\\Users\\[A-Za-z0-9_-]+\\'
        $config = Get-InsperaConfig
        $config.logDirectories.Count | Should -BeGreaterThan 0
        $config.fallbackToUserTemp | Should -Be $true
    }
}
