function Write-InsperaGuiResult {
    param(
        $RichTextBox,
        $Result
    )

    $RichTextBox.Clear()

    if ($Result.Summary) {
        $summaryColor = switch ($Result.Status) {
            'ok' { Get-InsperaGuiColor 'pass' }
            'issues' { Get-InsperaGuiColor 'warn' }
            'error' { Get-InsperaGuiColor 'fail' }
            default { [System.Drawing.Color]::Black }
        }
        Write-InsperaGuiLine -RichTextBox $RichTextBox -Text $Result.Summary -Color $summaryColor -Bold $true
        Write-InsperaGuiLine -RichTextBox $RichTextBox -Text '' -Color ([System.Drawing.Color]::Black)
    }

    foreach ($section in $Result.Sections) {
        if ($section.Heading) {
            Write-InsperaGuiLine -RichTextBox $RichTextBox -Text $section.Heading -Color (Get-InsperaGuiColor 'heading') -Bold $true
        }

        $lineColor = Get-InsperaGuiColor -Level $section.Level
        foreach ($line in $section.Lines) {
            $color = $lineColor
            if ($line -match '^\[PASS\]') { $color = Get-InsperaGuiColor 'pass' }
            elseif ($line -match '^\[FAIL\]') { $color = Get-InsperaGuiColor 'fail' }
            elseif ($line -match '^\[WARN\]') { $color = Get-InsperaGuiColor 'warn' }
            Write-InsperaGuiLine -RichTextBox $RichTextBox -Text $line -Color $color
        }
        Write-InsperaGuiLine -RichTextBox $RichTextBox -Text '' -Color ([System.Drawing.Color]::Black)
    }

    $RichTextBox.SelectionStart = 0
    $RichTextBox.ScrollToCaret()
}
