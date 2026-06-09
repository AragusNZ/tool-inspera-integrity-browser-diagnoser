function Get-InsperaDataPath {
    param([string]$FileName)
    Join-Path (Get-InsperaRoot) "data\$FileName"
}
