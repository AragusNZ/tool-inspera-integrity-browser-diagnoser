function Get-InsperaGuiColor {
    param([string]$Level)

    switch ($Level) {
        'pass' { return [System.Drawing.Color]::FromArgb(0, 120, 0) }
        'fail' { return [System.Drawing.Color]::FromArgb(180, 0, 0) }
        'warn' { return [System.Drawing.Color]::FromArgb(180, 120, 0) }
        'heading' { return [System.Drawing.Color]::FromArgb(0, 90, 140) }
        default { return [System.Drawing.Color]::FromArgb(60, 60, 60) }
    }
}
