<#

.SYNOPSIS
    PowerShell script to detect the Push Notification Setting Enabled.

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
$RegKeyFullPaths = @("HKCU:\Control Panel\International")
$sShortDateFormat = 'dd.MM.yyyy'
$RegKeysShortDateValue = (get-itemproperty $RegKeyFullPaths -name 'sShortDate').sShortDate

Try {

    If ($RegKeysShortDateValue -cne $sShortDateFormat) {
        Write-host 'Short Date Format is incorrect. Remediation required.'
        Write-Verbose 'Short Date Formatis incorrect. Remediation required.'
        Exit 1

    }
    Else { 
        write-host 'Short Date Format is correct. No remediation required.'
        Write-Verbose 'Short Date Format is correct. No remediation required.'
        Exit 0
        
    }
    
}

Catch {

    $ErrorMessage = $_.Exception.Message 
    Write-Warning $ErrorMessage
    Exit 1

}
