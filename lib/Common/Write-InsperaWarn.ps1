function Write-InsperaWarn {
    param([string]$Message)
    Write-Host "  [WARN] $Message" -ForegroundColor Yellow
    Add-InsperaOutputLine -Message $Message -Level 'warn'
}
