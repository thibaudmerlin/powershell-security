<#
.SYNOPSIS
    Extracts last activity information for devices enrolled in Intune.

.DESCRIPTION
    This script connects to Microsoft Graph, retrieves all devices managed by Intune,
    and reports their last synchronization activity. It helps identify inactive devices
    for security review or decommissioning.

.PARAMETER DeviceType
    Optional. Filter devices by type (e.g., "Windows", "iOS", "Android", "macOS").
    If not specified, all device types will be included.

.PARAMETER InactivityThreshold
    Number of days to consider a device inactive. Default is 30 days.

.PARAMETER OutputPath
    Path for the CSV export. If not specified, output will only be displayed in console.

.PARAMETER SortBy
    Sorts the output by either "DeviceName" (alphabetical) or "LastSync" (days since last sync).
    Default is "DeviceName".

.PARAMETER DeviceStatus
    Filter devices by status: "All", "Inactive", or "Active".

.EXAMPLE
    .\check-inactive-device.ps1
    Displays all Intune-enrolled devices and their last connection date.

.EXAMPLE
    .\check-inactive-device.ps1 -DeviceType "Windows" -InactivityThreshold 45 -OutputPath "C:\temp\InactiveDevices.csv"
    Generates an inactivity report for Windows devices and exports to CSV.

.EXAMPLE
    .\check-inactive-device.ps1 -DeviceStatus Inactive -SortBy LastSync
    Displays only inactive devices, sorted by days since last sync (most inactive first).
    
.NOTES
    Version:        1.0
    Author:         Thibaud Merlin
    Creation Date:  April 3, 2025
    Prerequisites:  Microsoft Graph PowerShell SDK modules
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Windows", "iOS", "Android", "macOS", "All")]
    [string]$DeviceType = "All",
    
    [Parameter(Mandatory = $false)]
    [int]$InactivityThreshold = 30,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("DeviceName", "LastSync")]
    [string]$SortBy = "DeviceName",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Inactive", "Active")]
    [string]$DeviceStatus = "All"
)

# Function to check if the Microsoft Graph modules are installed
function Confirm-ModuleInstalled {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        Write-Host "The $ModuleName module is not installed. Installing now..." -ForegroundColor Yellow
        Install-Module -Name $ModuleName -Scope CurrentUser -Force
    }
}

# Function to ensure connection to Microsoft Graph with appropriate permissions
function Connect-ToMicrosoftGraph {
    try {
        # Check for existing connection
        $context = Get-MgContext -ErrorAction SilentlyContinue
        
        if (-not $context) {
            Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
            Connect-MgGraph -Scopes "DeviceManagementManagedDevices.Read.All" -ErrorAction Stop
        }
        else {
            # Check if we have required permissions
            $requiredScopes = @("DeviceManagementManagedDevices.Read.All")
            $missingScopes = $requiredScopes | Where-Object { $context.Scopes -notcontains $_ }
            
            if ($missingScopes) {
                Write-Host "Reconnecting to Microsoft Graph with required permissions..." -ForegroundColor Cyan
                Disconnect-MgGraph -ErrorAction SilentlyContinue
                Connect-MgGraph -Scopes $requiredScopes -ErrorAction Stop
            }
        }
        
        Write-Host "Successfully connected to Microsoft Graph" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to connect to Microsoft Graph: $_"
        exit 1
    }
}

# Function to get all Intune-enrolled devices
function Get-IntuneDevices {
    param (
        [Parameter(Mandatory = $false)]
        [string]$DeviceTypeFilter = "All"
    )
    
    try {
        Write-Host "Retrieving Intune-enrolled devices..." -ForegroundColor Cyan
        
        # Get all managed devices from Intune
        $allDevices = Get-MgDeviceManagementManagedDevice -All
        
        if (-not $allDevices -or $allDevices.Count -eq 0) {
            Write-Warning "No Intune-enrolled devices found."
            return @()
        }
        
        Write-Host "Found $($allDevices.Count) Intune-enrolled devices." -ForegroundColor Green
        
        # Apply device type filter if specified
        if ($DeviceTypeFilter -ne "All") {
            $filteredDevices = $allDevices | Where-Object { $_.OperatingSystem -eq $DeviceTypeFilter }
            Write-Host "Filtered to $($filteredDevices.Count) $DeviceTypeFilter devices." -ForegroundColor Cyan
            return $filteredDevices
        }
        
        return $allDevices
    }
    catch {
        Write-Error "Failed to retrieve Intune-enrolled devices: $_"
        return @()
    }
}

# Main script execution starts here
try {
    # Verify required modules are installed
    Confirm-ModuleInstalled -ModuleName "Microsoft.Graph.Authentication"
    Confirm-ModuleInstalled -ModuleName "Microsoft.Graph.DeviceManagement"
    
    # Import necessary modules
    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.DeviceManagement
    
    # Connect to Microsoft Graph
    Connect-ToMicrosoftGraph
    
    # Get Intune-enrolled devices
    $devices = Get-IntuneDevices -DeviceTypeFilter $DeviceType
    
    if ($devices.Count -eq 0) {
        Write-Warning "No devices found matching the specified criteria."
        exit 0
    }
    
    # Create a collection to store device activity information
    $deviceActivityReport = @()
    
    # Process each device
    $counter = 0
    foreach ($device in $devices) {
        $counter++
        $progress = [math]::Round(($counter / $devices.Count) * 100, 0)
        Write-Progress -Activity "Processing devices" -Status "$counter of $($devices.Count) ($progress%)" -PercentComplete $progress

        # Calculate days since last sync
        $lastSyncDateTime = $device.LastSyncDateTime
        $daysSinceLastSync = $null
        
        if ($lastSyncDateTime) {
            $daysSinceLastSync = [math]::Round((New-TimeSpan -Start $lastSyncDateTime -End (Get-Date)).TotalDays, 0)
        }
        
        # Calculate if device is inactive
        $isInactive = if ($daysSinceLastSync -gt $InactivityThreshold -or $null -eq $daysSinceLastSync) { $true } else { $false }
        
        # Skip device if it doesn't match our activity filter
        if (($DeviceStatus -eq "Inactive" -and -not $isInactive) -or 
        ($DeviceStatus -eq "Active" -and $isInactive)) {
        continue
        }
        
        # Create device activity object
        $deviceActivity = [PSCustomObject]@{
            DeviceName = $device.DeviceName
            Manufacturer = $device.Manufacturer
            Model = $device.Model
            SerialNumber = $device.SerialNumber
            IMEI = $device.IMEI
            OS = $device.OperatingSystem
            OSVersion = $device.OSVersion
            LastSyncDateTime = $lastSyncDateTime
            DaysSinceLastSync = $daysSinceLastSync
            IsInactive = $isInactive
            ComplianceState = $device.ComplianceState
            OwnerType = $device.OwnerType
            EnrolledDateTime = $device.EnrolledDateTime
            UserId = $device.UserId
            UserPrincipalName = $device.UserPrincipalName
            DeviceId = $device.Id
        }
        
        $deviceActivityReport += $deviceActivity
    }
    
    Write-Progress -Activity "Processing devices" -Completed
    
    # If no devices match our criteria after filtering
    if ($deviceActivityReport.Count -eq 0) {
        Write-Warning "No devices match the specified criteria after filtering for inactive devices."
        exit 0
    }
    
    # Sort the report based on the SortBy parameter
    if ($SortBy -eq "DeviceName") {
        $deviceActivityReport = $deviceActivityReport | Sort-Object -Property DeviceName
    } else {
        $deviceActivityReport = $deviceActivityReport | Sort-Object -Property DaysSinceLastSync -Descending
    }
    
    # Display the report on console
    Write-Host "`nDevice Activity Report:" -ForegroundColor Cyan
    Write-Host "Inactivity threshold: $InactivityThreshold days" -ForegroundColor Cyan
    
    # Display filter information
    if ($DeviceStatus -ne "All") {
        Write-Host "Showing only $DeviceStatus devices" -ForegroundColor Yellow
    }
    
    # Format the report for display
    $formattedReport = $deviceActivityReport | ForEach-Object {
        $inactiveStatus = if ($_.IsInactive) { "Inactive" } else { "Active" }
        
        [PSCustomObject]@{
            DeviceName = $_.DeviceName
            OS = $_.OS
            Model = $_.Model
            LastSync = if ($_.LastSyncDateTime) { $_.LastSyncDateTime.ToString("yyyy-MM-dd") } else { "Never" }
            DaysSinceLastSync = if ($null -eq $_.DaysSinceLastSync) { "N/A" } else { $_.DaysSinceLastSync }
            Status = $inactiveStatus
            ComplianceState = $_.ComplianceState
            UserPrincipalName = $_.UserPrincipalName
        }
    }
    
    # Display the report
    $formattedReport | Format-Table -AutoSize
    
    # Output summary
    $inactiveCount = ($deviceActivityReport | Where-Object { $_.IsInactive }).Count
    $activeCount = ($deviceActivityReport | Where-Object { -not $_.IsInactive }).Count
    $byOSReport = $deviceActivityReport | Group-Object -Property OS | Select-Object Name, Count
    
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "- Total devices in report: $($deviceActivityReport.Count)" -ForegroundColor White
    Write-Host "- Active devices: $activeCount" -ForegroundColor Green
    Write-Host "- Inactive devices: $inactiveCount" -ForegroundColor $(if ($inactiveCount -gt 0) { "Yellow" } else { "Green" })
    
    Write-Host "`nDevice breakdown by OS:" -ForegroundColor Cyan
    foreach ($osGroup in $byOSReport) {
        Write-Host "- $($osGroup.Name): $($osGroup.Count) devices" -ForegroundColor White
    }
    
    # Export to CSV if OutputPath is specified
    if ($OutputPath) {
        try {
            $outputDirectory = Split-Path -Parent $OutputPath
            if ($outputDirectory -and -not (Test-Path -Path $outputDirectory)) {
                New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
            }
            
            $deviceActivityReport | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to export report to CSV: $_"
        }
    }
}
catch {
    Write-Error "An unexpected error occurred: $_"
}
finally {
    # Disconnect from Microsoft Graph
    Disconnect-MgGraph -ErrorAction SilentlyContinue
    Write-Host "Disconnected from Microsoft Graph" -ForegroundColor Gray
}