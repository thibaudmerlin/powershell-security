#==========================================================================================
#
# Script Name:     disable-AppGuard.ps1
# Description:     Disable App Guard Windows Feature
#
# Change Log:      T.Merlin      30 Nov. 2023        Script Created       
#    
#==========================================================================================

#region Config
$client = "customer name"
$logPath = "$env:ProgramData\$client\Logs"
$logFile = "$logPath\Disable-AppGuard.log"
#endregion
#region Logging
if (!(Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}
Start-Transcript -Path "$logFile" -Force
#endregion
#region script
if ((Get-WindowsOptionalFeature -Online -FeatureName "Windows-Defender-ApplicationGuard").State -eq "Enabled") {
    try {
        Disable-WindowsOptionalFeature -Online -FeatureName "Windows-Defender-ApplicationGuard"
        Write-Output "The Windows Feature Defender Application Guard is now disabled"
    }
    catch{
        $errMsg = $_.Exception.Message
        Write-Output $errMsg
    }
}
else {
    Write-Output "The Windows Feature Defender Application Guard is not installed/enabled"
}
Stop-Transcript
#endregion