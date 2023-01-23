<#

.SYNOPSIS
    PowerShell script to remediate Defender ATP Service.

.EXAMPLE
    .\UAT-Win10-01-Remediate-DefenderATPRunning.ps1

.DESCRIPTION
    This PowerShell script is deployed as a remediation script using Proactive Remediations in Microsoft Endpoint Manager/Intune.

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
$logFile = "$logPath\WATPRemediation.log"

$sdbin = <to Be replaced>
$WMIRegPath = @("HKLM:\SYSTEm\CurrentControlSet\Control\WMI\Security")
$DataCollectionPath = @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection")
$WATPPoliciesPath = @("HKLM:\SOFTWARE\Policies\Microsoft\Windows Advanced Threat Protection")
$WMIKey1 = <to Be replaced>
$WMIKey2 = <to Be replaced>
$DataCollectionKey1 = "DisableEnterpriseAuthProxy"
$DataCollectionValue1 = 1
$WATPKey1 = <to Be replaced>
$WATPKey2 = "OnboardingInfo"
[string]$WATPValue2 = <to Be replaced>
$WATPServiceName = "SENSE"
$WATPStatusPath = @("HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status")
$WATPStatusKey = "OnboardingState"
$WATPStatusValue = 1
$Source = @"
using System; 
using System.IO; 
using System.Runtime.InteropServices; 
using Microsoft.Win32.SafeHandles; 
using System.ComponentModel; 
public static class Elam{ [DllImport("Kernel32", CharSet=CharSet.Auto, SetLastError=true)] 
public static extern bool InstallELAMCertificateInfo(SafeFileHandle handle); 
public static void InstallWdBoot(string path) { 
var stream = File.Open(path, FileMode.Open, FileAccess.Read, FileShare.Read); 
var handle = stream.SafeFileHandle; 
if (!InstallELAMCertificateInfo(handle)) { 
throw new Win32Exception(Marshal.GetLastWin32Error()); 
}
} }
"@
#endregion
#region logging
if (!(Test-Path -Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force
}
Start-Transcript -Path $logFile -Force
#endregion
#region script
$WMIKeyValue1 = get-itemproperty $WMIRegPath -name $WMIKey1 -ErrorAction Ignore
If ($WMIKeyValue1) {
    Write-Host "The Key $WMIKey1 exist"
}
Else {
    New-ItemProperty -Path $WMIRegPath -Name $WMIKey1 -PropertyType Binary -Value $sdbin -Force
}
$WMIKeyValue2 = get-itemproperty $WMIRegPath -name $WMIKey2 -ErrorAction Ignore
If ($WMIKeyValue2) {
    Write-Host "The Key $WMIKey2 exist"
}
Else {
    New-ItemProperty -Path $WMIRegPath -Name $WMIKey2 -PropertyType Binary -Value $sdbin -Force
}

$DataCollectionKeyValue = get-itemproperty $DataCollectionPath -name $DataCollectionKey1 -ErrorAction Ignore
If ($DataCollectionKeyValue) {
    Write-Host "The Key $DataCollectionKey1 exist"
}
Else {
    New-ItemProperty -Path $DataCollectionPath -Name $DataCollectionKey1 -PropertyType DWord -Value $DataCollectionValue1 -Force
}

Add-Type -TypeDefinition $Source
$driverPath = $env:SystemRoot + '\System32\Drivers\WdBoot.sys'; 
[Elam]::InstallWdBoot($driverPath)

$WATPKey1Value = get-itemproperty $WATPKey1 -name $WATPValue1 -ErrorAction Ignore
If ($WATPKey1Value) {
    Remove-ItemProperty -Path $WATPPoliciesPath -Name $WATPKey1 -Force
}
Else {
    Write-Host "The Key $WATPKey1 doesn't exist"
}
$WATPKey2Value = get-itemproperty $WATPPoliciesPath -name $WATPKey2 -ErrorAction Ignore
If ($WATPKey2Value) {
    Write-Host "The Key $WATPKey2 exist"
}
Else {
    New-ItemProperty -Path $WATPPoliciesPath -Name $WATPKey2 -PropertyType string -Value $WATPValue2 -Force
}

$ServiceStatus = Get-Service -Name $WATPServiceName -ErrorAction SilentlyContinue
If ($ServiceStatus.Status -ne "Running") {
    Start-Service -Name $WATPServiceName
    $sw = New-Object System.Diagnostics.Stopwatch
    $sw.Start()
    $timeSpan = New-TimeSpan -Minutes 2
    while (((Get-Service -Name $WATPServiceName -ErrorAction SilentlyContinue).Status -ne "Running") -and ($sw.ElapsedMilliseconds -lt $timeSpan.TotalMilliseconds)) {
        start-sleep -Seconds 2
    }
    $ServiceStatus = Get-Service -Name $WATPServiceName -ErrorAction SilentlyContinue
}
Write-Host "The Service $WATPServiceName status is : $ServiceStatus"

$WATPStatusKeyValue = (get-itemproperty $WATPStatusPath -name $WATPStatusKey -ErrorAction Ignore).OnboardingState
If ($WATPStatusKeyValue -eq $WATPStatusValue) {
    Write-Host "The Onboarding State is : $WATPStatusKeyValue, that means everything is OK"
    Stop-Transcript
    Exit 0
}
Else {
    Write-Host "The Onboarding State is : $WATPStatusKeyValue, that means something is NOT OK"
    Stop-Transcript-
    Exit 1
}
    
Stop-Transcript