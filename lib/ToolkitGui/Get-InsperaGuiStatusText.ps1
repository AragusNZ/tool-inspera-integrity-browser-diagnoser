function Get-InsperaGuiStatusText {
    param($Result)

    switch ($Result.Status) {
        'ok' { return $Result.Summary }
        'issues' { return $Result.Summary }
        'error' { return $Result.Summary }
        default { return 'Done' }
    }
}
