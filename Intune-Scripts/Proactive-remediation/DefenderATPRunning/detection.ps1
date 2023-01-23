<#

.SYNOPSIS
    PowerShell script to detect if Defender ATP Service is installed and running.

.EXAMPLE
    .\UAT-Win10-01-Detect-DefenderATPRunning.ps1

.DESCRIPTION
    This PowerShell script is deployed as a detection script using Proactive Remediations in Microsoft Endpoint Manager/Intune.

.LINK
    https://docs.microsoft.com/en-us/mem/analytics/proactive-remediations

.NOTES
    Version:        1.0
    Creation Date:  January 23, 2023
    Author:         Thibaud Merlin

#>

[CmdletBinding()]

Param (

)

# Set Variables
$client = "Company"
$logPath = "$ENV:ProgramData\$client\Logs"
$logFile = "$logPath\WATPDetection.log"

$ServiceName = "SENSE"
$RegKeyFullPaths = @("HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status")
$DefenderOnboardingKey = "OnboardingState"
$OnboardingStateValue = 1
$RegKeyDefenderValue = (get-itemproperty $RegKeyFullPaths -name $DefenderOnboardingKey -ErrorAction Ignore).OnboardingState
#region logging
if (!(Test-Path -Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force
}
Start-Transcript -Path $logFile -Force
#endregion
#region detection
Try {
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    If ($null -eq $Service) {
        Write-host 'Defender ATP is not installed. Remediation required.'
        Write-Verbose 'Defender ATP is not installed. Remediation required.'
        Exit 1 
    }
    Else {
        If ($Service.Status -ne "Running") {
            Write-host 'Defender ATP Service is not running. Remediation required.'
            Write-Verbose 'Defender ATP Service is not running. Remediation required.'
            Exit 1
        }
        Else {
            If ($RegKeyDefenderValue -eq $OnboardingStateValue) {
                write-host 'Defender ATP is installed and running. No remediation required.'
                Write-Verbose 'Defender ATP is installed and running. No remediation required.'
                Exit 0
            }
            Else {
                Write-host 'Defender ATP Service is running but not well onboarded. Remediation required.'
                Write-Verbose 'Defender ATP Service is running but not well onboarded. Remediation required.'
                Exit 1
            }
            

        }
    }   
}

Catch {

    $ErrorMessage = $_.Exception.Message 
    Write-Warning $ErrorMessage
    Exit 1

}
Stop-Transcript
#endregion