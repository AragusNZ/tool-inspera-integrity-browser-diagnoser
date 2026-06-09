function Write-InsperaPass {
    param([string]$Message)
    Write-Host "  [PASS] $Message" -ForegroundColor Green
    Add-InsperaOutputLine -Message $Message -Level 'pass'
}
