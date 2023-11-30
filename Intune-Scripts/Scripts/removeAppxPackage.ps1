#==========================================================================================
#
# Script Name:     removeAppXPackage.ps1
# Description:     Remove unused Appx Package on Win11
#
# Change Log:      T.Merlin      28 Aug 2023        Script Created       
#    
#==========================================================================================

#region Config
$client = "Customer"
$logPath = "$env:ProgramData\$client\Logs"
$logFile = "$logPath\Remove-AppxUseless.log"
#endregion
#region Logging
if (!(Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}
Start-Transcript -Path "$logFile" -Force
#endregion
# Define Variables
$appToRemove = "*Xbox*","*WindowsFeedbackHub*","*BingNews*", "*MicrosoftSolitaireCollection*", "*WindowsSoundRecorder*", "*BingWeather*"

try 
{
    foreach ($app in $appToRemove){
        Get-AppxPackage -AllUsers $app | Remove-AppxPackage
        Get-AppxProvisionedPackage –online | where-object {$_.packagename –like "$app"} | Remove-AppxProvisionedPackage –online
        exit 0
    }
}   
catch{
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}