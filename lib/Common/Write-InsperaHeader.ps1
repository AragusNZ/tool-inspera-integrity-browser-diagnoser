function Write-InsperaHeader {
    param([string]$Title)
    Write-Host ''
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host ''
    Add-InsperaOutputLine -Message "=== $Title ===" -Level 'heading'
}
