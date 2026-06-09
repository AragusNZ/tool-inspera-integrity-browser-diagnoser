function Get-InsperaFailureDetailsFromLog {
    param(
        [string[]]$Lines,
        [int]$FailureLineNumber
    )

    $details = [System.Collections.Generic.List[string]]::new()
    $start = [Math]::Max(0, $FailureLineNumber - 3)
    $end = [Math]::Min($Lines.Count - 1, $FailureLineNumber + 4)

    for ($i = $start; $i -le $end; $i++) {
        if ($i + 1 -eq $FailureLineNumber) { continue }
        $line = $Lines[$i]
        if ($line -match 'reason|because|detected|virtual|remote|VM|RDP|Hyper-V|offset|latency|memory|display|monitor|process|blocked|permission|SSE4|version|battery|power|plugged|iceworm|Fyne|GLFW|cancellation|connectionCheck|session status|clock offset|active displays') {
            $details.Add($line.Trim())
        }
    }

    return @($details | Select-Object -Unique)
}
