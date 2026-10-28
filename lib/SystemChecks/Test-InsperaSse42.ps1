function Test-InsperaSse42 {
    $result = @{
        Name = 'CPU SSE4.2'
        Passed = $false
        Message = ''
        Details = @{}
    }

    $cpuName = ''
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
        $cpuName = $cpu.Name
        $result.Details.Name = $cpuName
    } catch {
        # name is informational only
    }

    try {
        # PF_SSE4_2_INSTRUCTIONS_AVAILABLE = 38
        if (-not ('Inspera.CpuFeature' -as [type])) {
            Add-Type -Namespace Inspera -Name CpuFeature -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern bool IsProcessorFeaturePresent(int feature);
'@ -ErrorAction Stop
        }
        $hasSse42 = [Inspera.CpuFeature]::IsProcessorFeaturePresent(38)
        $result.Details.Source = 'IsProcessorFeaturePresent'
    } catch {
        # Older Windows without PF_SSE4_2: fall back to CPU family heuristic
        $hasSse42 = $cpuName -match 'Core\(TM\) i[3579]|Core\(TM\) Ultra|Ryzen|Xeon|EPYC|Core\(TM\) \d+'
        $result.Details.Source = 'cpu-name-heuristic'
        if (-not $hasSse42) {
            $result.Informational = $true
            $result.Message = "Could not verify SSE4.2 for '$cpuName'  - Inspera will check this itself"
            return $result
        }
    }

    if ($hasSse42) {
        $result.Passed = $true
        $result.Message = 'CPU supports SSE4.2'
    } else {
        $result.Message = 'CPU does NOT support SSE4.2  - Inspera cannot run on this PC, use a different computer'
    }

    return $result
}
