function Write-InsperaFail {
    param([string]$Message)
    Write-Host "  [FAIL] $Message" -ForegroundColor Red
    Add-InsperaOutputLine -Message $Message -Level 'fail'
}
