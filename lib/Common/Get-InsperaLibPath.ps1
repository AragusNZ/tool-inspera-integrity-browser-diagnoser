function Get-InsperaLibPath {
    param([string]$FileName)
    Join-Path (Get-InsperaRoot) "lib\$FileName"
}
