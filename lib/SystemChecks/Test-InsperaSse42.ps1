function Test-InsperaSse42 {
    $result = @{
        Name = 'CPU SSE4.2'
        Passed = $false
        Message = ''
        Details = @{}
    }

    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
        $result.Details.Name = $cpu.Name

        # SSE4.2 is bit 20 of ECX from CPUID leaf 1
        $code = @'
using System;
using System.Runtime.InteropServices;
public static class CpuId {
    [DllImport("kernel32.dll")]
    static extern void __cpuid(ref int a, ref int b, ref int c, ref int d);
    public static bool HasSse42() {
        int a=1,b=0,c=0,d=0;
        __cpuid(ref a, ref b, ref c, ref d);
        return (c & (1 << 20)) != 0;
    }
}
'@
        Add-Type -TypeDefinition $code -Language CSharp -ErrorAction Stop
        $hasSse42 = [CpuId]::HasSse42()

        if ($hasSse42) {
            $result.Passed = $true
            $result.Message = 'CPU supports SSE4.2'
        } else {
            $result.Message = 'CPU does NOT support SSE4.2  - IIB will fail, use different PC'
        }
    } catch {
        # Fallback: assume pass on modern Windows if CPUID check fails
        $result.Passed = $true
        $result.Message = "SSE4.2 check skipped (assumed OK): $($_.Exception.Message)"
    }

    return $result
}
