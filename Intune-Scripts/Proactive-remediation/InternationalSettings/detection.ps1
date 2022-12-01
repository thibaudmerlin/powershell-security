<#

.SYNOPSIS
    PowerShell script to detect the International Settings.

.EXAMPLE
    .\UAT-Win10-01-Detect-CplIntSettings.ps1

.DESCRIPTION
    This PowerShell script is deployed as a detection script using Proactive Remediations in Microsoft Endpoint Manager/Intune.

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

    If ($RegKeysDecimalValue -eq ',') {
        Write-host 'Decimal symbol is incorrect. Remediation required.'
        Write-Verbose 'Decimal symbol is incorrect. Remediation required.'
        Exit 1

    }
    ElseIf ($RegKeysGroupValue -eq ',' -OR $RegKeysGroupValue -eq ' ') {
        Write-host 'Decimal group is incorrect. Remediation required.'
        Write-Verbose 'Decimal group is incorrect. Remediation required.'
        Exit 1

    }
    Else { 
        write-host 'Decimal symbol and group are correct. No remediation required.'
        Write-Verbose 'Decimal symbol and group are correct. No remediation required.'
        Exit 0
        
    }
    
}

Catch {

    $ErrorMessage = $_.Exception.Message 
    Write-Warning $ErrorMessage
    Exit 1

}
