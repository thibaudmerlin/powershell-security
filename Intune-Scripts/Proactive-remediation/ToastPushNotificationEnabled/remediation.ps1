<#

.SYNOPSIS
    PowerShell script to remediate the Push Notification Setting Enabled.

.EXAMPLE
    .\UAT-Win10-01-Remediate-ToastEnabled.ps1

.DESCRIPTION
    This PowerShell script is deployed as a remediation script using Proactive Remediations in Microsoft Endpoint Manager/Intune.

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

Try {
    if (get-itemproperty $RegKeyFullPaths -name 'ToastEnabled' -ErrorAction Ignore){
        Write-Verbose 'Updating Toast Enabled Key to 1'
        Set-itemproperty $RegKeyFullPaths -name 'ToastEnabled' -value $ToastEnabledKey
        Exit 0
    }
    else {
        Write-Verbose 'Creating Toast Enabled Key to 1'
        New-ItemProperty -Path $RegKeyFullPaths -Name 'ToastEnabled' -Value $ToastEnabledKey -PropertyType DWord
        Exit 0
    }
    


}

Catch {

    $ErrorMessage = $_.Exception.Message 
    Write-Warning $ErrorMessage
    Exit 1

}