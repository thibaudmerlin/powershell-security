$PackageName = "Teams-new-Backgrounds"
#region Config
$client = "<customer name>"
$logPath = "$env:ProgramData\$client\Logs"
$logFile = "$logPath\UnInstall-Teams-BG.log"
#endregion
#region Logging
if (!(Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}
Start-Transcript -Path "$logFile" -Force

try{
    # Local Folder 
    $TeamsBG_Folder = "$env:LOCALAPPDATA\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Backgrounds\Uploads"

    # Reference IDs
    $TeamsBG_ref = "$TeamsBG_Folder\TeamsBackgrounds.csv"

    if(Test-Path $TeamsBG_ref){
        # Clean up old files
        $TeamsBG_old = Import-Csv -Path $TeamsBG_ref
        foreach($TeamsBG in $TeamsBG_old.Name){
            Write-Host "Removing $TeamsBG ..."
            Remove-Item -Path "$TeamsBG_Folder\$TeamsBG*" -Force
        }
    }else{
        Write-Host "No old files found"
    }
    

    # Remove Detection Key
    Remove-Item -Path "HKCU:\SOFTWARE\scloud\$PackageName" -Force

    
}catch{
    Write-Error "$_"
}

Stop-Transcript