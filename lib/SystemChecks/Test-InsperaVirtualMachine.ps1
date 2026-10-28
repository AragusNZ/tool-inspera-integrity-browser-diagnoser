function Test-InsperaVirtualMachine {
    # IIB's Environment check refuses to run inside a VM.
    $result = @{
        Name = 'Virtual machine'
        Passed = $true
        Message = 'Running on physical hardware'
        Details = @{}
    }

    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $fingerprint = "$($cs.Manufacturer) $($cs.Model)"
        $result.Details.Manufacturer = $cs.Manufacturer
        $result.Details.Model = $cs.Model

        if ($fingerprint -match 'VirtualBox|VMware|Virtual Machine|QEMU|KVM|Parallels|Xen|Bochs|innotek') {
            $result.Passed = $false
            $result.Message = "This is a virtual machine ($fingerprint)  - Inspera only runs on a physical PC"
        }
    } catch {
        $result.Message = 'Virtual machine check skipped'
    }

    return $result
}
