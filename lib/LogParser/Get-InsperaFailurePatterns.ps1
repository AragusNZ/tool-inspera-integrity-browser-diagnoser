function Get-InsperaFailurePatterns {
    return @(
        @{ Key = 'Environment - failure'; Pattern = 'Environment\s*-\s*failure|Environment\s+check\s+failed|Environment\s+error'; Priority = 10 }
        @{ Key = 'Process blocklist - failure'; Pattern = 'Process\s+blocklist\s*-\s*failure|Failed to retrieve process blocklist'; Priority = 10 }
        @{ Key = 'Connection quality - failure'; Pattern = 'Connection quality\s*-\s*failure|Too poor connection quality'; Priority = 10 }
        @{ Key = 'Clock accuracy - failure'; Pattern = 'Clock accuracy\s*-\s*failure|Clock accuracy error'; Priority = 10 }
        @{ Key = 'Number of screens - failure'; Pattern = 'Number of screens\s*-\s*failure|Incorrect number of screens'; Priority = 10 }
        @{ Key = 'Power state - failure'; Pattern = 'Power state\s*-\s*failure|No external power supply'; Priority = 10 }
        @{ Key = 'Memory Check - failure'; Pattern = 'Memory Check\s*[-–]\s*failure|Not enough free memory'; Priority = 10 }
        @{ Key = 'CPU features - failure'; Pattern = 'CPU features\s*-\s*failure|Unsupported CPU'; Priority = 10 }
        @{ Key = 'App version - failure'; Pattern = 'App version\s*-\s*failure|Obsolete app version'; Priority = 10 }
        @{ Key = 'App location - failure'; Pattern = 'App location\s*[-–]\s*failure|Wrong application location'; Priority = 10 }
        @{ Key = 'After completion - failed'; Pattern = 'After completion\s*-\s*failed|Login configuration error'; Priority = 10 }
        @{ Key = 'Device check failure'; Pattern = 'Device check failure'; Priority = 10 }
        @{ Key = 'Incorrect keyboard language'; Pattern = 'Incorrect keyboard language'; Priority = 10 }
        @{ Key = 'desktop changed'; Pattern = 'active desktop has changed|desktop has changed'; Priority = 20 }
        @{ Key = 'failed to close'; Pattern = 'failed to close the following applications|Inspera failed to close the following applications'; Priority = 15 }
        @{ Key = 'Screen Capture'; Pattern = 'detected the following applications that have access to Screen Capture|access to Screen Capture'; Priority = 10 }
        @{ Key = 'Failed to capture screen'; Pattern = 'Failed to capture screen|Failed to capture your screen'; Priority = 10 }
        @{ Key = 'Cannot upload files'; Pattern = 'Cannot upload files|Failed to upload'; Priority = 10 }
        @{ Key = 'Webcam'; Pattern = 'Webcam too dark|Webcam Capture\s*-\s*failure'; Priority = 10 }
        @{ Key = 'Full disk access'; Pattern = 'Full disk access\s*-\s*failure|Failed to acquire full disk access'; Priority = 10 }
        @{ Key = 'iceworm failure'; Pattern = 'iceworm exited: exit status [1-9]\d*'; Priority = 18 }
        @{ Key = 'system check aborted'; Pattern = 'cancellation detected'; Priority = 17 }
        @{ Key = 'UI runtime error'; Pattern = 'Fyne error:|GLFW poll event error'; Priority = 12 }
    )
}
