<#
.SYNOPSIS
    Extracts last login activity information for users based on their assigned licenses in Entra ID.

.DESCRIPTION
    This script connects to Microsoft Graph, retrieves all users with specific license types,
    and reports their last sign-in activity. It helps identify inactive user accounts for 
    license optimization or security review.

.PARAMETER LicenseTypes
    Array of license display names to check (e.g., "Microsoft 365 E3", "Power BI Pro").
    Use the parameter -ListAvailableLicenses to see available licenses in your tenant.
    
.PARAMETER ListAvailableLicenses
    Switch parameter to list all available licenses in the tenant and exit.

.PARAMETER InactivityThreshold
    Number of days to consider a user inactive. Default is 30 days.

.PARAMETER OutputPath
    Path for the CSV export. If not specified, output will only be displayed in console.

.EXAMPLE
    .\check-inactivity.ps1 -ListAvailableLicenses
    Lists all available license types in your tenant with their friendly names.

.EXAMPLE
    .\check-inactivity.ps1 -LicenseTypes "SPE_E5", "Power BI Pro" -InactivityThreshold 45 -OutputPath "C:\temp\InactiveUsers.csv"
    Generates an inactivity report for all users with the specified licenses.
    
.NOTES
    Version:        2.0
    Author:         Thibaud Merlin
    Creation Date:  April 3, 2025
    Prerequisites:  Microsoft Graph PowerShell SDK modules
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, ParameterSetName = "ReportByLicense")]
    [string[]]$LicenseTypes,
    
    [Parameter(Mandatory = $false)]
    [int]$InactivityThreshold = 30,
    
    [Parameter(Mandatory = $false, ParameterSetName = "ReportByLicense")]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $true, ParameterSetName = "ListLicenses")]
    [switch]$ListAvailableLicenses
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
            Connect-MgGraph -Scopes "User.Read.All", "Organization.Read.All", "AuditLog.Read.All" -ErrorAction Stop
        }
        else {
            # Check if we have all required permissions
            $requiredScopes = @("User.Read.All", "Organization.Read.All", "AuditLog.Read.All")
            $missingScopes = $requiredScopes | Where-Object { $context.Scopes -notcontains $_ }
            
            if ($missingScopes) {
                Write-Host "Reconnecting to Microsoft Graph with additional required permissions..." -ForegroundColor Cyan
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

# Function to get all available license types in the tenant
function Get-AvailableLicenses {
    try {
        Write-Host "Retrieving available licenses in the tenant..." -ForegroundColor Cyan
        
        $subscribedSkus = Get-MgSubscribedSku -All
        
        if (-not $subscribedSkus -or $subscribedSkus.Count -eq 0) {
            Write-Warning "No licenses found in the tenant."
            return @()
        }
        
        $licenseInfo = @()
        foreach ($sku in $subscribedSkus) {
            # Get friendly name for the license
            $displayName = $sku.SkuPartNumber
            
            # For some common license types, provide a more user-friendly name
            $friendlyName = switch ($sku.SkuPartNumber) {
                # Microsoft 365 and Office 365 licenses
                "O365_BUSINESS_PREMIUM" { "Microsoft 365 Business Premium" }
                "SPE_E3" { "Microsoft 365 E3" }
                "SPE_E5" { "Microsoft 365 E5" }
                
                # Exchange and Communication
                "EXCHANGESTANDARD" { "Exchange Online Plan 1" }
                "EXCHANGEENTERPRISE" { "Exchange Online Plan 2" }
                "MCOSTANDARD" { "Teams Phone Standard" }
                "MCOCAP" { "Microsoft Teams Audio Conferencing" }
                "MCOPSTNC" { "Microsoft Teams Phone System Calling Plan" }
                "PHONESYSTEM_VIRTUALUSER" { "Teams Phone Resource Account" }
                
                # Teams Products
                "Microsoft_Teams_Premium" { "Microsoft Teams Premium" }
                "Microsoft_Teams_Rooms_Pro" { "Microsoft Teams Rooms Pro" }
                
                # Project and Visio
                "PROJECTPROFESSIONAL" { "Project Plan 3" }
                "PROJECT_P1" { "Project Plan 1" }
                "VISIOCLIENT" { "Visio Plan 2" }
                "VISIO_PLAN2_DEPT" { "Visio Plan 2" }
                
                # Power Platform
                "POWER_BI_PRO" { "Power BI Pro" }
                "PBI_PREMIUM_PER_USER" { "Power BI Premium Per User" }
                "POWER_BI_STANDARD" { "Power BI Free" }
                "POWERAPPS_DEV" { "Power Apps Developer Plan" }
                "POWERAPPS_PER_USER" { "Power Apps Per User Plan" }
                "FLOW_FREE" { "Power Automate Free" }
                "FLOW_PER_USER" { "Power Automate Per User Plan" }
                "Power_Pages_vTrial_for_Makers" { "Power Pages Trial" }
                
                # Security and Compliance
                "EMSPREMIUM" { "Enterprise Mobility + Security E5" }
                "EMS" { "Enterprise Mobility + Security E3" }
                "IDENTITY_THREAT_PROTECTION" { "Microsoft Defender for Identity" }
                "TVM_Premium_Standalone" { "Microsoft Defender Vulnerability Management" }
                "RMSBASIC" { "Rights Management Basic" }
                "Workload_Identities_P2" { "Entra ID Workload Identity Premium P2" }
                
                # Windows
                "WIN_ENT_E5" { "Windows 10/11 Enterprise E5" }
                "WIN_ENT_E3" { "Windows 10/11 Enterprise E3" }
                "WINDOWS_STORE" { "Windows Store for Business" }
                
                # Entra (Azure AD) products
                "Microsoft_Entra_Internet_Access_Premium" { "Entra Internet Access Premium" }
                "Microsoft_Entra_Private_Access_Premium" { "Entra Private Access Premium" }
                "INTUNE_A_D" { "Intune Plan A Direct" }
                
                # Cloud PC
                "CPC_E_2C_8GB_128GB" { "Windows 365 Enterprise 2vCPU/8GB/128GB" }
                "CPC_E_4C_16GB_128GB" { "Windows 365 Enterprise 4vCPU/16GB/128GB" }
                "CPC_E_4C_16GB_256GB" { "Windows 365 Enterprise 4vCPU/16GB/256GB" }
                
                # Dynamics and Other
                "DYN365_BUSINESS_MARKETING" { "Dynamics 365 Marketing" }
                "SHAREPOINTSTORAGE" { "SharePoint Storage" }
                "Microsoft_365_Copilot" { "Microsoft 365 Copilot" }
                "CCIBOTS_PRIVPREV_VIRAL" { "Copilot Chat Preview" }
                
                # Default fallback - use the SKU part number when no friendly name is available
                default { $displayName }
            }
            
            $licenseInfo += [PSCustomObject]@{
                SkuId = $sku.SkuId
                SkuPartNumber = $sku.SkuPartNumber
                DisplayName = $friendlyName
                TotalUnits = $sku.PrepaidUnits.Enabled
                ConsumedUnits = $sku.ConsumedUnits
                AvailableUnits = ($sku.PrepaidUnits.Enabled - $sku.ConsumedUnits)
            }
        }
        
        return $licenseInfo
    }
    catch {
        Write-Error "Failed to retrieve available licenses: $_"
        return @()
    }
}

# Function to get users with specific license types
function Get-UsersWithLicense {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$LicenseDisplayNames,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$AvailableLicenses
    )
    
    try {
        # Initialize a hashtable to store unique users by license type
        $usersByLicense = @{}
        $licenseData = @()
        
        # For each license type, find the corresponding SKU ID and get users
        foreach ($licenseDisplayName in $LicenseDisplayNames) {
            $license = $AvailableLicenses | Where-Object { $_.DisplayName -eq $licenseDisplayName -or $_.SkuPartNumber -eq $licenseDisplayName }
            
            if (-not $license) {
                Write-Warning "License '$licenseDisplayName' not found in tenant. Skipping."
                continue
            }
            
            $skuId = $license.SkuId
            
            Write-Host "Finding users with license: $($license.DisplayName) ($skuId)..." -ForegroundColor Cyan
            
            # Get all users with this license
            $licensedUsers = Get-MgUser -Filter "assignedLicenses/any(x:x/skuId eq $skuId)" -All
            
            if (-not $licensedUsers -or $licensedUsers.Count -eq 0) {
                Write-Warning "No users found with license '$($license.DisplayName)'."
                continue
            }
            
            Write-Host "Found $($licensedUsers.Count) users with license '$($license.DisplayName)'." -ForegroundColor Green
            
            # Store license information for reporting
            $licenseData += [PSCustomObject]@{
                LicenseName = $license.DisplayName
                SkuId = $skuId
                UserCount = $licensedUsers.Count
                TotalLicenses = $license.TotalUnits
                ConsumedLicenses = $license.ConsumedUnits
                AvailableLicenses = $license.AvailableUnits
            }
            
            # Add users to our collection, avoiding duplicates but tracking which licenses they have
            foreach ($user in $licensedUsers) {
                if (-not $usersByLicense.ContainsKey($user.Id)) {
                    $usersByLicense[$user.Id] = @{
                        UserId = $user.Id
                        Licenses = @($license.DisplayName)
                    }
                }
                else {
                    # Add this license to the user's list of licenses
                    $usersByLicense[$user.Id].Licenses += $license.DisplayName
                }
            }
        }
        
        return @{
            Users = $usersByLicense
            LicenseData = $licenseData
        }
    }
    catch {
        Write-Error "Failed to retrieve users with licenses: $_"
        return @{
            Users = @{}
            LicenseData = @()
        }
    }
}

# Main script execution starts here
try {
    # Verify required modules are installed
    Confirm-ModuleInstalled -ModuleName "Microsoft.Graph.Authentication"
    Confirm-ModuleInstalled -ModuleName "Microsoft.Graph.Users"
    Confirm-ModuleInstalled -ModuleName "Microsoft.Graph.Identity.DirectoryManagement"
    
    # Import necessary modules
    Import-Module Microsoft.Graph.Authentication
    Import-Module Microsoft.Graph.Users
    Import-Module Microsoft.Graph.Identity.DirectoryManagement
    
    # Connect to Microsoft Graph
    Connect-ToMicrosoftGraph
    
    # Get all available license types
    $availableLicenses = Get-AvailableLicenses
    
    # If -ListAvailableLicenses parameter is specified, display available licenses and exit
    if ($ListAvailableLicenses) {
        Write-Host "`nAvailable licenses in the tenant:" -ForegroundColor Cyan
        $availableLicenses | Sort-Object -Property DisplayName | Format-Table DisplayName, SkuPartNumber, TotalUnits, ConsumedUnits, AvailableUnits -AutoSize
        
        Write-Host "`nUse these display names with the -LicenseTypes parameter to generate a report." -ForegroundColor Yellow
        return
    }
    
    # Ensure license types are specified
    if (-not $LicenseTypes -or $LicenseTypes.Count -eq 0) {
        Write-Error "No license types specified. Use -LicenseTypes parameter to specify licenses or -ListAvailableLicenses to see available options."
        exit 1
    }
    
    # Get users with specified license types
    $result = Get-UsersWithLicense -LicenseDisplayNames $LicenseTypes -AvailableLicenses $availableLicenses
    $allUsers = $result.Users
    $licenseData = $result.LicenseData
    
    if ($allUsers.Count -eq 0) {
        Write-Warning "No users found with any of the specified license types."
        exit 0
    }
    
    Write-Host "Total unique users across all specified licenses: $($allUsers.Count)" -ForegroundColor Green
    
    # Create a collection to store user activity information
    $userActivityReport = @()
    
    # Get sign-in activity report
    Write-Host "Retrieving user sign-in activity (this may take a while)..." -ForegroundColor Cyan
    
    # Process each unique user
    $counter = 0
    foreach ($userId in $allUsers.Keys) {
        $counter++
        $progress = [math]::Round(($counter / $allUsers.Count) * 100, 0)
        Write-Progress -Activity "Processing users" -Status "$counter of $($allUsers.Count) ($progress%)" -PercentComplete $progress

        try {
            # Get user details
            $user = Get-MgUser -UserId $userId -Property "id,userPrincipalName,displayName,accountEnabled,jobTitle,department,signInActivity" -ErrorAction SilentlyContinue
            
            if ($user) {
                # Calculate days since last sign-in
                $lastSignInDateTime = $null
                $daysSinceLastSignIn = $null
                
                if ($user.SignInActivity -and $user.SignInActivity.LastSignInDateTime) {
                    $lastSignInDateTime = $user.SignInActivity.LastSignInDateTime
                    $daysSinceLastSignIn = [math]::Round((New-TimeSpan -Start $lastSignInDateTime -End (Get-Date)).TotalDays, 0)
                }
                
                # Create user activity object
                $userActivity = [PSCustomObject]@{
                    UserPrincipalName = $user.UserPrincipalName
                    DisplayName = $user.DisplayName
                    LastSignInDateTime = $lastSignInDateTime
                    DaysSinceLastSignIn = $daysSinceLastSignIn
                    IsInactive = if ($daysSinceLastSignIn -gt $InactivityThreshold -or $null -eq $daysSinceLastSignIn) { $true } else { $false }
                    AccountEnabled = $user.AccountEnabled
                    JobTitle = $user.JobTitle
                    Department = $user.Department
                    UserId = $userId
                    Licenses = ($allUsers[$userId].Licenses -join "; ")
                }
                
                $userActivityReport += $userActivity
            }
        }
        catch {
            Write-Warning "Error processing user $userId`: $_"
        }
    }
    
    Write-Progress -Activity "Processing users" -Completed
    
    # Sort the report by days since last sign-in (descending) and format for output
    $userActivityReport = $userActivityReport | Sort-Object -Property DaysSinceLastSignIn -Descending
    
    # Display the report on console
    Write-Host "`nUser Inactivity Report for specified license types:" -ForegroundColor Cyan
    Write-Host "Inactivity threshold: $InactivityThreshold days" -ForegroundColor Cyan
    
    # Display license summary first
    Write-Host "`nLicense Summary:" -ForegroundColor Cyan
    foreach ($license in $licenseData) {
        Write-Host "- $($license.LicenseName): $($license.UserCount) users ($($license.ConsumedLicenses)/$($license.TotalLicenses) licenses assigned)" -ForegroundColor White
    }
    
    # Format the report for display
    $formattedReport = $userActivityReport | ForEach-Object {
        $inactiveStatus = if ($_.IsInactive) { "Inactive" } else { "Active" }
        $statusColor = if ($_.IsInactive) { "Red" } else { "Green" }
        $enabledStatus = if ($_.AccountEnabled) { "Enabled" } else { "Disabled" }
        $enabledColor = if ($_.AccountEnabled) { "Green" } else { "Red" }
        
        [PSCustomObject]@{
            UserPrincipalName = $_.UserPrincipalName
            DisplayName = $_.DisplayName
            LastSignIn = if ($_.LastSignInDateTime) { $_.LastSignInDateTime.ToString("yyyy-MM-dd") } else { "Never" }
            DaysSinceLastSignIn = if ($null -eq $_.DaysSinceLastSignIn) { "N/A" } else { $_.DaysSinceLastSignIn }
            Status = $inactiveStatus
            AccountStatus = $enabledStatus
            Department = $_.Department
            Licenses = $_.Licenses
        }
    }
    
    # Display the report
    $formattedReport | Format-Table -AutoSize
    
    # Output summary
    $inactiveCount = ($userActivityReport | Where-Object { $_.IsInactive }).Count
    $activeCount = ($userActivityReport | Where-Object { -not $_.IsInactive }).Count
    $disabledCount = ($userActivityReport | Where-Object { -not $_.AccountEnabled }).Count
    
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "- Total users: $($userActivityReport.Count)" -ForegroundColor White
    Write-Host "- Active users: $activeCount" -ForegroundColor Green
    Write-Host "- Inactive users: $inactiveCount" -ForegroundColor $(if ($inactiveCount -gt 0) { "Yellow" } else { "Green" })
    Write-Host "- Disabled accounts: $disabledCount" -ForegroundColor $(if ($disabledCount -gt 0) { "Yellow" } else { "Green" })
    
    # License optimization recommendation
    $potentialSavings = ($userActivityReport | Where-Object { $_.IsInactive -and $_.AccountEnabled }).Count
    if ($potentialSavings -gt 0) {
        Write-Host "`nLicense Optimization Recommendation:" -ForegroundColor Yellow
        Write-Host "- $potentialSavings active license(s) assigned to inactive users could potentially be reassigned" -ForegroundColor Yellow
    }
    
    # Export to CSV if OutputPath is specified
    if ($OutputPath) {
        try {
            $outputDirectory = Split-Path -Parent $OutputPath
            if ($outputDirectory -and -not (Test-Path -Path $outputDirectory)) {
                New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
            }
            
            $userActivityReport | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
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