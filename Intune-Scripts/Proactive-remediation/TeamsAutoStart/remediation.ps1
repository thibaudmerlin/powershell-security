<#

.SYNOPSIS
    PowerShell script to remediate the Teams Autostart to none.

.EXAMPLE
    .\UAT-Win10-01-Remediate-TeamsAutostart.ps1

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
$RegKeyFullPaths = @("HKCU:\Software\Microsoft\Windows\CurrentVersion\Run")
$TeamsAutostartKey = "com.squirrel.Teams.Teams"

    if (get-itemproperty $RegKeyFullPaths -name 'ToastEnabled' -ErrorAction Ignore){
        Write-Verbose 'Deleting Registry Key for Teams Autostart'
        Remove-ItemProperty $RegKeyFullPaths -Name $TeamsAutostartKey
    }
    # Teams Config Path
    $teamsConfigFile = "$env:APPDATA\Microsoft\Teams\desktop-config.json"
    $teamsConfig = Get-Content $teamsConfigFile -Raw
 
    if ( $teamsConfig -match "openAtLogin`":false") {
        break
    }
    elseif ( $teamsConfig -match "openAtLogin`":true" ) {
    # Update Teams Config
    $teamsConfig = $teamsConfig -replace "`"openAtLogin`":true","`"openAtLogin`":false"
    }
    else {
        $teamsAutoStart = ",`"appPreferenceSettings`":{`"openAtLogin`":false}}"
        $teamsConfig = $teamsConfig -replace "}$",$teamsAutoStart
    }
 
    $teamsConfig | Set-Content $teamsConfigFile
    Exit 0
