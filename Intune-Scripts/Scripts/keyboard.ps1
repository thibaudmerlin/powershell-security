#==========================================================================================
#
# Script Name:     keyboard.ps1
# Description:     Change Keyboard layout 
#
# Change Log:      T.Merlin      22 Feb 2023        Script Created       
#    
#==========================================================================================

# Define Variables
$TeamsApp = Get-AppxProvisionedPackage -online | where-object {$_.PackageName -like "*MicrosoftTeams*"}

try 
{
    if ($TeamsApp.DisplayName -eq "MicrosoftTeams")
        {
            Write-Output "Teams Built-in Present"
            Exit 1
        }
    else
        {
            Write-Output "Teams Built-in Not Present"
            Exit 0
        }
}   
catch{
    $errMsg = $_.Exception.Message
    Write-Error $errMsg
    exit 1
}