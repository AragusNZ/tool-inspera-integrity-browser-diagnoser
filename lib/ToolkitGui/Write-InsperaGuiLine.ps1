function Write-InsperaGuiLine {
    param(
        $RichTextBox,
        [string]$Text,
        [System.Drawing.Color]$Color,
        [switch]$Bold
    )

    $RichTextBox.SelectionStart = $RichTextBox.TextLength
    $RichTextBox.SelectionLength = 0
    $RichTextBox.SelectionColor = $Color
    $RichTextBox.SelectionFont = if ($Bold) {
        New-Object System.Drawing.Font($RichTextBox.Font, [System.Drawing.FontStyle]::Bold)
    } else {
        $RichTextBox.Font
    }
    $RichTextBox.AppendText("$Text`r`n")
    $RichTextBox.SelectionFont = $RichTextBox.Font
}
