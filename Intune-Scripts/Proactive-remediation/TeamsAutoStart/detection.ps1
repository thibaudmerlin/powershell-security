<#

.SYNOPSIS
    PowerShell script to detect the the Teams Autostart to none.

.EXAMPLE
    .\UAT-Win10-01-Detect-TeamsAutostart.ps1

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
$RegKeyFullPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run")
$TeamsAutostartKey = "com.squirrel.Teams.Teams"

Try {

    If (Get-ItemProperty $RegKeyFullPaths -Name $TeamsAutostartKey -ErrorAction Ignore) {
        Write-host 'Teams Autostart is Enabled. Remediation required.'
        Write-Verbose 'Teams Autostart is Enabled. Remediation required.'
        Exit 1

    }
    Else { 
        write-host 'Teams Autostart is Disabled. No remediation required.'
        Write-Verbose 'Teams Autostart is Disabled. No remediation required.'
        Exit 0
        
    }
    
}

Catch {

    $ErrorMessage = $_.Exception.Message 
    Write-Warning $ErrorMessage
    Exit 1

}
