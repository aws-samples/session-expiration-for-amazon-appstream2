<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0
#>
# Uncomment the next line if you've installed the modularized version of AWS Tools for PowerShell.
# Import-Module AWS.Tools.Lambda
Add-Type -assembly System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

Function Format-TimeRemaining {
	Param ([TimeSpan] $timeRemaining)

	switch ($timeRemaining)
	{
		{ $timeRemaining.Days -eq 0 } {
			$timeRemainingDays = ''
		}
		{ $timeRemaining.Days -eq 1 } {
			$timeRemainingDays = '1 day, '
		}
		{ $timeRemaining.Days -gt 1 } {
			$timeRemainingDays = '{0:%d} days, ' -f $timeRemaining
		}
		{ $timeRemaining.Hours -eq 0 } {
			$timeRemainingHours = ''
		}
		{ $timeRemaining.Hours -eq 1 } {
			$timeRemainingHours = '1 hour, '
		}
		{ $timeRemaining.Hours -gt 1 } {
			$timeRemainingHours = '{0:%h} hours, ' -f $timeRemaining
		}
		{ $timeRemaining.Minutes -eq 0 } {
			$timeRemainingMinutes = ''
		}
		{ $timeRemaining.Minutes -eq 1 } {
			$timeRemainingMinutes = '1 minute'
		}
		{ $timeRemaining.Minutes -gt 1 } {
			$timeRemainingMinutes = '{0:%m} minutes' -f $timeRemaining
		}
	}
	return 'Time remaining: {0}{1}{2}.' -f $timeRemainingDays, $timeRemainingHours, $timeRemainingMinutes
}

if ($env:AppStream_Resource_Type -eq 'image-builder') {
	# Simulate session expiration on image builders.
	Start-Sleep -Seconds 1
	$statusCode = 200
	$responseBody = @{'maxExpiration'=(Get-Date).AddMinutes(11).ToString('yyyy-MM-ddTHH:mm:ss.ffffffzzz')}
} else {
	# Invoke Lambda function and parse response.
	$payload = @{
		sessionId=(Get-ItemPropertyValue -Path 'HKCU:\Environment' -Name AppStream_Session_ID)
		stackName=(Get-ItemPropertyValue -Path 'HKCU:\Environment' -Name AppStream_Stack_Name)
		resourceName=(Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name AppStream_Resource_Name)
		userName=(Get-ItemPropertyValue -Path 'HKCU:\Environment' -Name AppStream_UserName)
		userAccessMode=(Get-ItemPropertyValue -Path 'HKCU:\Environment' -Name AppStream_User_Access_Mode)
		action='describe'
	} | ConvertTo-Json

	$invokeResponse = Invoke-LMFunction `
	-FunctionName AppStream2SessionExpirationProxy `
	-Payload $payload `
	-ProfileName appstream_machine_role

	$responseBody = [System.Text.Encoding]::Default.GetString($invokeResponse.Payload.ToArray()) | ConvertFrom-Json
	$statusCode = $responseBody.statusCode
}

$mainForm = New-Object System.Windows.Forms.Form
if ($env:AppStream_Resource_Type -eq 'image-builder') {
	$mainForm.Text = 'Session Info (simulated)'
} else {
	$mainForm.Text = 'Session Info'
}
$mainForm.controlbox = $true
$mainForm.Width = 350
$mainForm.Height = 100
$mainForm.StartPosition = 'manual'
$mainForm.Location = new-object System.Drawing.Size(70,20)

# Allow Escape key to close window.
$mainForm.KeyPreview = $True#;
$mainForm.Add_KeyDown({
	if ($_.KeyCode -eq 'Escape'){
		$mainForm.Close()
	}
})

if ($statusCode -eq 200) {
    $maxExpiration = [Datetime]::ParseExact($responseBody.maxExpiration, 'yyyy-MM-ddTHH:mm:ss.ffffffzzz', $null)
    $endLabel = New-Object System.Windows.Forms.Label
    $endLabel.Text = 'This session will end by {0}.' -f $maxExpiration
    $endLabel.Location  = New-Object System.Drawing.Point(5,10)
    $endLabel.AutoSize = $true
    $mainForm.Controls.Add($endLabel)

    $remainingLabel = New-Object System.Windows.Forms.Label
    $remainingLabel.Location  = New-Object System.Drawing.Point(5,30)
    $remainingLabel.AutoSize = $true
    $remainingLabel.Text = Format-TimeRemaining($maxExpiration - (Get-Date))
    $mainForm.Controls.Add($remainingLabel)

    $countdown = New-Object System.Windows.Forms.Timer
    $countdown.Interval = 60000 # ms
    $countdown.add_Tick({
	    $timeRemaining = ($maxExpiration - (Get-Date))
	    if ($timeRemaining -lt (New-TimeSpan -Minutes 10)) {
		    $remainingLabel.Font = New-Object System.Drawing.Font($remainingLabel.Font.Name,$remainingLabel.Font.Size,[System.Drawing.FontStyle]::Bold)
			$mainForm.TopMost = $true
	    }
	    $remainingLabel.Text = Format-TimeRemaining($maxExpiration - (Get-Date))
    })

    $countdown.Start()
    $mainForm.ShowDialog()
    $countdown.Dispose()
    Remove-Variable countdown
} else {
    $errorLabel = New-Object System.Windows.Forms.Label
    $errorLabel.Text = 'Error ({0}) retrieving session expiration.' -f $statusCode
    $errorLabel.Location  = New-Object System.Drawing.Point(5,10)
    $errorLabel.AutoSize = $true
    $mainForm.Controls.Add($errorLabel)
    $mainForm.ShowDialog()
}