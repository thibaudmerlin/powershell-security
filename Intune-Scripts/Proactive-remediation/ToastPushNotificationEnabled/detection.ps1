<#

.SYNOPSIS
    PowerShell script to detect the International Settings.

.EXAMPLE
    .\UAT-Win10-01-Detect-ToastEnabled.ps1

.DESCRIPTION
    This PowerShell script is deployed as a detection script using Proactive Remediations in Microsoft Endpoint Manager/Intune.

.LINK
    https://docs.microsoft.com/en-us/mem/analytics/proactive-remediations

.NOTES
    Version:        1.0
    Creation Date:  December 05, 2022
    Author:         Thibaud Merlin

#>

[CmdletBinding()]

Param (

)

# Set Variables
$RegKeyFullPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications")
$ToastEnabledKey = 1
$RegKeyToastValue = (get-itemproperty $RegKeyFullPaths -name 'ToastEnabled' -ErrorAction Ignore).ToastEnabled

Try {

    If ($RegKeyToastValue -ne $ToastEnabledKey) {
        Write-host 'Toast Push Notification Enabled is incorrect. Remediation required.'
        Write-Verbose 'Toast Push Notification Enabled is incorrect. Remediation required.'
        Exit 1

    }
    Else { 
        write-host 'Toast Push Notification Enabled is correct. No remediation required.'
        Write-Verbose 'Toast Push Notification Enabled is correct. No remediation required.'
        Exit 0
        
    }
    
}

Catch {

    $ErrorMessage = $_.Exception.Message 
    Write-Warning $ErrorMessage
    Exit 1

}
