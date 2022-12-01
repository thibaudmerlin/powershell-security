<#

.SYNOPSIS
    PowerShell script to remediate the Control Panel International Settings.

.EXAMPLE
    .\UAT-Win10-01-Remediate-CplIntSettings.ps1

.DESCRIPTION
    This PowerShell script is deployed as a remediation script using Proactive Remediations in Microsoft Endpoint Manager/Intune.

.LINK
    https://docs.microsoft.com/en-us/mem/analytics/proactive-remediations

.NOTES
    Version:        1.0
    Creation Date:  November 30, 2022
    Author:         Thibaud Merlin

#>

[CmdletBinding()]

Param (

)

# Set Variables
$RegKeyFullPaths = @("HKCU:\Control Panel\International")
$sShortDateFormat = 'dd/MM/yyyy'

Try {

    Write-Verbose 'Updating Short Date Format to dd/MM/yyyy...'
    Set-itemproperty $RegKeyFullPaths -name 'sDecimal' -value $sShortDateFormat
}

Catch {

    $ErrorMessage = $_.Exception.Message 
    Write-Warning $ErrorMessage
    Exit 1

}