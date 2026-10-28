function Get-InsperaExamReminders {
    param(
        [ValidateSet('Prepare', 'Guided', 'GuiIntro')]
        [string]$Context = 'Prepare'
    )

    switch ($Context) {
        'Prepare' {
            return @(
                'Use a single monitor during Inspera system checks',
                'Close virtual desktops (Win+Tab) before starting',
                'Disable VPN unless your institution requires it',
                'Plug in charger if prompted by Inspera',
                'Do not connect to this PC with Remote Desktop',
                'Set your keyboard language to the one your institution approves',
                'Restart your PC before the exam if it has been on for days',
                'Close Chrome extensions (especially Avast) before exam'
            )
        }
        'Guided' {
            return @(
                'Disconnect secondary monitor if you have one (reconnect after checks if allowed)',
                'Plug in your charger',
                'Close any virtual desktops (Win+Tab)',
                'Disable VPN unless your institution requires it',
                'Do not connect via Remote Desktop and do not run Inspera in a virtual machine',
                'Set your keyboard language to the one your institution approves',
                'Launch Inspera Integrity Browser and complete system checks',
                'If it fails, click Why did Inspera fail? in this toolkit'
            )
        }
        'GuiIntro' {
            return @(
                'Click a button above to get started.',
                '',
                'Recommended order:',
                '  1. Prepare my PC for the exam',
                '  2. Am I ready?',
                '  3. Launch Inspera',
                '  4. If it fails: Why did Inspera fail?'
            )
        }
    }
}
