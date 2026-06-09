function Show-InsperaToolkitGui {
    param(
        [string]$RootPath = $PSScriptRoot
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Inspera Exam Helper'
    $form.Size = New-Object System.Drawing.Size(720, 640)
    $form.MinimumSize = New-Object System.Drawing.Size(600, 500)
    $form.StartPosition = 'CenterScreen'
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = 'Inspera Exam Helper'
    $titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.Location = New-Object System.Drawing.Point(16, 12)
    $titleLabel.AutoSize = $true
    $form.Controls.Add($titleLabel)

    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = 'Prepare your PC and understand Inspera failures'
    $subtitleLabel.Location = New-Object System.Drawing.Point(18, 42)
    $subtitleLabel.AutoSize = $true
    $subtitleLabel.ForeColor = [System.Drawing.Color]::DimGray
    $form.Controls.Add($subtitleLabel)

    $btnPrepare = New-Object System.Windows.Forms.Button
    $btnPrepare.Text = 'Prepare my PC for the exam'
    $btnPrepare.Location = New-Object System.Drawing.Point(16, 76)
    $btnPrepare.Size = New-Object System.Drawing.Size(210, 36)
    $form.Controls.Add($btnPrepare)

    $btnReady = New-Object System.Windows.Forms.Button
    $btnReady.Text = 'Am I ready?'
    $btnReady.Location = New-Object System.Drawing.Point(236, 76)
    $btnReady.Size = New-Object System.Drawing.Size(140, 36)
    $form.Controls.Add($btnReady)

    $btnDiagnose = New-Object System.Windows.Forms.Button
    $btnDiagnose.Text = 'Why did Inspera fail?'
    $btnDiagnose.Location = New-Object System.Drawing.Point(386, 76)
    $btnDiagnose.Size = New-Object System.Drawing.Size(180, 36)
    $form.Controls.Add($btnDiagnose)

    $btnGuided = New-Object System.Windows.Forms.Button
    $btnGuided.Text = 'Run recommended steps'
    $btnGuided.Location = New-Object System.Drawing.Point(16, 120)
    $btnGuided.Size = New-Object System.Drawing.Size(210, 32)
    $form.Controls.Add($btnGuided)

    $resultsBox = New-Object System.Windows.Forms.RichTextBox
    $resultsBox.Location = New-Object System.Drawing.Point(16, 162)
    $resultsBox.Size = New-Object System.Drawing.Size(672, 400)
    $resultsBox.Anchor = 'Top, Bottom, Left, Right'
    $resultsBox.ReadOnly = $true
    $resultsBox.BackColor = [System.Drawing.Color]::White
    $resultsBox.BorderStyle = 'FixedSingle'
    $resultsBox.Text = "Click a button above to get started.`r`n`r`nRecommended order:`r`n  1. Prepare my PC for the exam`r`n  2. Am I ready?`r`n  3. Launch Inspera`r`n  4. If it fails: Why did Inspera fail?"
    $form.Controls.Add($resultsBox)

    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Text = 'Ready'
    $statusLabel.Location = New-Object System.Drawing.Point(16, 568)
    $statusLabel.Size = New-Object System.Drawing.Size(500, 24)
    $statusLabel.Anchor = 'Bottom, Left'
    $statusLabel.ForeColor = [System.Drawing.Color]::DimGray
    $form.Controls.Add($statusLabel)

    $btnOpenFolder = New-Object System.Windows.Forms.LinkLabel
    $btnOpenFolder.Text = 'Advanced: open folder'
    $btnOpenFolder.Location = New-Object System.Drawing.Point(560, 568)
    $btnOpenFolder.Size = New-Object System.Drawing.Size(130, 24)
    $btnOpenFolder.Anchor = 'Bottom, Right'
    $form.Controls.Add($btnOpenFolder)

    $script:GuiRunspace = $null
    $script:GuiPowerShell = $null
    $script:GuiAsyncResult = $null
    $script:GuiPollTimer = $null

    $buttons = @($btnPrepare, $btnReady, $btnDiagnose, $btnGuided)

    function Set-InsperaGuiBusy {
        param([bool]$Busy, [string]$StatusText = 'Working...')

        foreach ($btn in $buttons) {
            $btn.Enabled = -not $Busy
        }
        $statusLabel.Text = $StatusText
        if ($Busy) {
            $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        } else {
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
        }
    }

    function Start-InsperaGuiAction {
        param(
            [string]$ActionName,
            [hashtable]$Parameters = @{}
        )

        if ($script:GuiPollTimer) {
            $script:GuiPollTimer.Stop()
            $script:GuiPollTimer.Dispose()
            $script:GuiPollTimer = $null
        }

        if ($script:GuiPowerShell) {
            if ($script:GuiAsyncResult -and -not $script:GuiAsyncResult.IsCompleted) {
                return
            }
            $script:GuiPowerShell.Dispose()
            $script:GuiPowerShell = $null
        }
        if ($script:GuiRunspace) {
            $script:GuiRunspace.Close()
            $script:GuiRunspace.Dispose()
            $script:GuiRunspace = $null
        }

        Set-InsperaGuiBusy -Busy $true -StatusText 'Working...'
        $resultsBox.Clear()
        Write-InsperaGuiLine -RichTextBox $resultsBox -Text 'Please wait...' -Color ([System.Drawing.Color]::DimGray)

        $scriptBlock = {
            param($Root, $Action, $Params)

            Set-Location $Root
            $lib = Join-Path $Root 'lib'
            . (Join-Path $lib 'Common.ps1')
            . (Join-Path $lib 'LogParser.ps1')
            . (Join-Path $lib 'ProcessManager.ps1')
            . (Join-Path $lib 'SystemChecks.ps1')
            . (Join-Path $lib 'ToolkitActions.ps1')

            switch ($Action) {
                'Prepare' {
                    return Invoke-InsperaPrepareToolkit -Apply -LogPath $Params.LogPath -InsperaUrl $Params.InsperaUrl `
                        -Proctored:([bool]$Params.Proctored) -MaxDisplays $Params.MaxDisplays
                }
                'Preflight' {
                    return Invoke-InsperaPreflightToolkit -LogPath $Params.LogPath -InsperaUrl $Params.InsperaUrl `
                        -Proctored:([bool]$Params.Proctored) -MaxDisplays $Params.MaxDisplays
                }
                'Diagnose' {
                    return Invoke-InsperaDiagnoseToolkit -LogPath $Params.LogPath -InsperaUrl $Params.InsperaUrl
                }
                'Guided' {
                    return Invoke-InsperaGuidedFlowToolkit -LogPath $Params.LogPath -InsperaUrl $Params.InsperaUrl `
                        -Proctored:([bool]$Params.Proctored) -MaxDisplays $Params.MaxDisplays
                }
                default { throw "Unknown action: $Action" }
            }
        }

        $script:GuiRunspace = [runspacefactory]::CreateRunspace()
        $script:GuiRunspace.Open()
        $script:GuiPowerShell = [powershell]::Create()
        $script:GuiPowerShell.Runspace = $script:GuiRunspace
        [void]$script:GuiPowerShell.AddScript($scriptBlock)
        [void]$script:GuiPowerShell.AddArgument($RootPath)
        [void]$script:GuiPowerShell.AddArgument($ActionName)
        [void]$script:GuiPowerShell.AddArgument($Parameters)

        $script:GuiAsyncResult = $script:GuiPowerShell.BeginInvoke()

        $script:GuiPollTimer = New-Object System.Windows.Forms.Timer
        $script:GuiPollTimer.Interval = 200
        $script:GuiPollTimer.Add_Tick({
            if (-not $script:GuiAsyncResult.IsCompleted) {
                return
            }

            $script:GuiPollTimer.Stop()

            try {
                $result = $script:GuiPowerShell.EndInvoke($script:GuiAsyncResult)
                if ($result -is [System.Array] -and $result.Count -gt 0) {
                    $result = $result[0]
                }

                if ($result) {
                    Write-InsperaGuiResult -RichTextBox $resultsBox -Result $result
                    $statusLabel.Text = Get-InsperaGuiStatusText -Result $result
                    $statusLabel.ForeColor = switch ($result.Status) {
                        'ok' { Get-InsperaGuiColor 'pass' }
                        'issues' { Get-InsperaGuiColor 'warn' }
                        'error' { Get-InsperaGuiColor 'fail' }
                        default { [System.Drawing.Color]::DimGray }
                    }
                }
            } catch {
                $resultsBox.Clear()
                Write-InsperaGuiLine -RichTextBox $resultsBox -Text 'Something went wrong.' -Color (Get-InsperaGuiColor 'fail') -Bold $true
                Write-InsperaGuiLine -RichTextBox $resultsBox -Text $_.Exception.Message -Color (Get-InsperaGuiColor 'fail')
                Write-InsperaGuiLine -RichTextBox $resultsBox -Text 'Ask exam support for help, or try again.' -Color ([System.Drawing.Color]::DimGray)
                $statusLabel.Text = 'Error'
                $statusLabel.ForeColor = Get-InsperaGuiColor 'fail'
            } finally {
                if ($script:GuiPowerShell) {
                    $script:GuiPowerShell.Dispose()
                    $script:GuiPowerShell = $null
                }
                if ($script:GuiRunspace) {
                    $script:GuiRunspace.Close()
                    $script:GuiRunspace.Dispose()
                    $script:GuiRunspace = $null
                }
                Set-InsperaGuiBusy -Busy $false -StatusText $statusLabel.Text
            }
        })
        $script:GuiPollTimer.Start()
    }

    $defaultParams = @{
        LogPath = $null
        InsperaUrl = $null
        Proctored = $false
        MaxDisplays = 1
    }

    $btnPrepare.Add_Click({
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "This will close apps like Discord, OBS, screen recorders, and other programs that can interfere with Inspera.`n`nContinue?",
            'Prepare my PC',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
            Start-InsperaGuiAction -ActionName 'Prepare' -Parameters $defaultParams
        }
    })

    $btnReady.Add_Click({
        Start-InsperaGuiAction -ActionName 'Preflight' -Parameters $defaultParams
    })

    $btnDiagnose.Add_Click({
        Start-InsperaGuiAction -ActionName 'Diagnose' -Parameters $defaultParams
    })

    $btnGuided.Add_Click({
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "This will prepare your PC (close interfering apps), check readiness, and show a short checklist.`n`nContinue?",
            'Run recommended steps',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
            Start-InsperaGuiAction -ActionName 'Guided' -Parameters $defaultParams
        }
    })

    $btnOpenFolder.Add_Click({
        Start-Process explorer.exe $RootPath
    })

    $form.Add_FormClosing({
        if ($script:GuiPollTimer) {
            $script:GuiPollTimer.Stop()
            $script:GuiPollTimer.Dispose()
        }
        if ($script:GuiPowerShell) {
            $script:GuiPowerShell.Dispose()
        }
        if ($script:GuiRunspace) {
            $script:GuiRunspace.Close()
            $script:GuiRunspace.Dispose()
        }
    })

    [void]$form.ShowDialog()
}
