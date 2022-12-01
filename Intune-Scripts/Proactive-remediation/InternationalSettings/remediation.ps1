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
$sDecimalSeparator = '.'
$sGroupSeparator = ','
$RegKeysDecimalValue = (get-itemproperty $RegKeyFullPaths -name 'sDecimal').sDecimal
$RegKeysGroupValue = (get-itemproperty $RegKeyFullPaths -name 'sThousand').sThousand

Try {

    Write-Verbose 'Updating Decimal Symbol Separator to Dot...'
    Set-itemproperty $RegKeyFullPaths -name 'sDecimal' -value '.'
    Set-itemproperty $RegKeyFullPaths -name 'sThousand' -value "'"
}

Catch {

    $ErrorMessage = $_.Exception.Message 
    Write-Warning $ErrorMessage
    Exit 1

}