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
                'Close Chrome extensions (especially Avast) before exam'
            )
        }
        'Guided' {
            return @(
                'Disconnect secondary monitor if you have one (reconnect after checks if allowed)',
                'Plug in your charger',
                'Close any virtual desktops (Win+Tab)',
                'Disable VPN unless your institution requires it',
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
