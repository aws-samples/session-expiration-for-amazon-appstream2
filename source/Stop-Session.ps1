<#
Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0
#>
# Uncomment the next line if you've installed the modularized version of AWS Tools for PowerShell.
# Import-Module AWS.Tools.Lambda
if ($env:AppStream_Resource_Type -eq 'image-builder') {
	Write-Output 'Operation not supported on image builders.'
} else {
	# Invoke Lambda function and parse response.
	$payload = @{
		sessionId=(Get-ItemPropertyValue -Path 'HKCU:\Environment' -Name AppStream_Session_ID)
		stackName=(Get-ItemPropertyValue -Path 'HKCU:\Environment' -Name AppStream_Stack_Name)
		resourceName=(Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name AppStream_Resource_Name)
		userName=(Get-ItemPropertyValue -Path 'HKCU:\Environment' -Name AppStream_UserName)
		userAccessMode=(Get-ItemPropertyValue -Path 'HKCU:\Environment' -Name AppStream_User_Access_Mode)
		action='expire'
	} | ConvertTo-Json

	$invokeResponse = Invoke-LMFunction `
	-FunctionName AppStream2SessionExpirationProxy `
	-Payload $payload `
	-ProfileName appstream_machine_role

	$responseBody = [System.Text.Encoding]::Default.GetString($invokeResponse.Payload.ToArray()) | ConvertFrom-Json
	$statusCode = $responseBody.statusCode

	if ($statusCode -eq 200) {
		Write-Output 'Expired session.'
	} else {
		Write-Output 'Error ({0}) expiring session.' -f $statusCode
	}
}