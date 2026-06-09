#Requires -Version 5.1

BeforeAll {
    $script:Root = Split-Path $PSScriptRoot -Parent
    $script:CommonDir = Join-Path $Root 'lib\Common'
    . (Join-Path $commonDir '00-State.ps1')
    . (Join-Path $commonDir 'Convert-InsperaCanonicalPath.ps1')
    . (Join-Path $commonDir 'Get-InsperaAppRoot.ps1')
}

Describe 'Get-InsperaAppRoot' {
    BeforeEach {
        $script:InsperaAppRoot = $null
    }

    It 'returns repo root when invoked from a top-level script' {
        $harness = Join-Path $Root 'AppRootTestHarness.ps1'
        @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Stop'
. '$($commonDir -replace "'", "''")\\00-State.ps1'
. '$($commonDir -replace "'", "''")\\Convert-InsperaCanonicalPath.ps1'
. '$($commonDir -replace "'", "''")\\Get-InsperaAppRoot.ps1'
Get-InsperaAppRoot
"@ | Set-Content -Path $harness -Encoding UTF8
        try {
            Convert-InsperaCanonicalPath (& $harness) | Should -Be (Convert-InsperaCanonicalPath (Resolve-Path $Root).Path)
        } finally {
            Remove-Item -Path $harness -Force -ErrorAction SilentlyContinue
        }
    }

    It 'returns exe directory when InvokedPath is provided' {
        $fakeExe = Join-Path $Root 'Inspera Exam Helper.exe'
        New-Item -Path $fakeExe -ItemType File -Force | Out-Null
        try {
            Convert-InsperaCanonicalPath (Get-InsperaAppRoot -InvokedPath $fakeExe) | Should -Be (Convert-InsperaCanonicalPath (Resolve-Path $Root).Path)
        } finally {
            Remove-Item -Path $fakeExe -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Get-InsperaRoot integration' {
    BeforeEach {
        $script:InsperaProjectRoot = $null
        $script:InsperaAppRoot = $null
    }

    It 'falls back to Get-InsperaAppRoot when project root is unset' {
        . (Join-Path $commonDir 'Get-InsperaRoot.ps1')
        (Resolve-Path (Get-InsperaRoot)).Path | Should -Be (Resolve-Path $Root).Path
    }
}
