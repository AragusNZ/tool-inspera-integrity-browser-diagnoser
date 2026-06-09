function Write-InsperaInfo {
    param([string]$Message)
    Write-Host "  [INFO] $Message" -ForegroundColor Gray
    Add-InsperaOutputLine -Message $Message -Level 'info'
}
