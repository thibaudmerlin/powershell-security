#region function
<#
.Synopsis
   Turns the integer stored in msDS-SupportedEncryptionTypes into a human readable value
.DESCRIPTION
   Turns the integer stored in msDS-SupportedEncryptionTypes into a human readable value
   For more info on the encryption types: https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/decrypting-the-selection-of-supported-kerberos-encryption-types/ba-p/1628797
.EXAMPLE
   Get-ETypeDefiniton 7
.PARAMETER msDSSupportedEncryptionTypes
    Returns an array of results indicating the supported encryption types
.PARAMETER AsString
    Returns the result as a comma delimited string
#>
function Get-ETypeDefinition
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $msDSSupportedEncryptionTypes,
        [switch] $AsString
    )
    Begin
    {
        $ETypes = [HASHTABLE]@{
            0 = "Not defined - defaults to RC4_HMAC_MD5"
            1 = "DES_CBC_CRC"
            2 = "DES_CBC_MD5"
            4 = "RC4"
            8 = "AES 128"
            16 = "AES 256"
        }
    }
    Process
    {
        $Types = $ETypes.keys | %{
            If([int]($msDSSupportedEncryptionTypes -band [int]$_) -ne 0){
                $ETypes[[int]$_]
            }
            Else {
                $Types = "Not Set"
            }
        }
        If($AsString){
            $Types -join(',')
        }Else{
            $Types
        }
    }
    End
    {
    }
}
<#
.Synopsis
   Get the SupportedEncryptionTypes related Security Advice
.DESCRIPTION
   Turns the integer stored in msDS-SupportedEncryptionTypes into a security advice
   For more info on the encryption types: https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/decrypting-the-selection-of-supported-kerberos-encryption-types/ba-p/1628797
.EXAMPLE
   Get-EncryptionTypeAdvice 7
.PARAMETER msDSSupportedEncryptionTypes
    Returns an the security advice for the encryption type
#>
function Get-EncryptionTypeAdvice
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $msDSSupportedEncryptionTypes
    )
    Begin
    {
        $ETypes = @{
            0 = 'Critical'
            1 = 'Critical'
            2 = 'Critical'
            3 = 'Critical'
            4 = 'Critical'
            5 = 'Critical'
            6 = 'Critical'
            7 = 'Critical'
            8 = 'Strong'
            9 = 'Critical'
            10 = 'Critical'
            11 = 'Critical'
            12 = 'Weak'
            13 = 'Critical'
            14 = 'Critical'
            15 = 'Critical'
            16 = 'Strong'
            17 = 'Critical'
            18 = 'Critical'
            19 = 'Critical'
            20 = 'Weak'
            21 = 'Critical'
            22 = 'Critical'
            23 = 'Critical'
            24 = 'Strong'
            25 = 'Critical'
            26 = 'Critical'
            27 = "Critical"
            28 = 'Weak'
            29 = 'Critical'
            30 = 'Critical'
            31 = 'Critical'
        }
        $Etype = $ETypes.keys -join "|"
    }
    Process
    {
        if ($msDSSupportedEncryptionTypes -match $Etype) {
        [int]$index = $matches[0]
        $Types = $ETypes.item($index)
        $Types
    }
        else {
        $Types = "NoAdvice"
        $Types
        }
    }
    End
    {
    }
}
#endregion
#region script

$keycolor = @{
    Critical = "Red"
    Strong = "Green"
    Weak = "Yellow"
    NoAdvice = "Magenta"
    }
$keys = $keycolor.keys -join "|"

$computers = Get-ADComputer -Filter * -Properties msDS-SupportedEncryptionTypes 
$computers = $computers | `
Group-Object msDS-SupportedEncryptionTypes | `
Select-Object Count,Name,@{N="EncryptionTypesAsString";E={Get-ETypeDefinition -msDSSupportedEncryptionTypes ($_.Name) -AsString}} | `
Select-Object Count,Name,EncryptionTypesAsString,@{N="EncryptionTypesAdvice";E={Get-EncryptionTypeAdvice -msDSSupportedEncryptionTypes ($_.Name)}}<#  | `
% {
    [string]@{
        Count   = $_.item(0)
        Name  = $_.Name
        EncryptionTypesAsString = $_.EncryptionTypesAsString
        EncryptionTypesAdvice = $_.EncryptionTypesAdvice
    } 
} #>
$users = Get-ADUser -Filter * -Properties msDS-SupportedEncryptionTypes 
$users = $users | `
Group-Object msDS-SupportedEncryptionTypes | `
Select-Object Count,Name,@{N="EncryptionTypesAsString";E={Get-ETypeDefinition -msDSSupportedEncryptionTypes ($_.Name) -AsString}} | `
Select-Object Count,Name,EncryptionTypesAsString,@{N="EncryptionTypesAdvice";E={Get-EncryptionTypeAdvice -msDSSupportedEncryptionTypes ($_.Name)}}

$gMSAs = Get-ADServiceAccount -Filter * -Properties msDS-SupportedEncryptionTypes 
$gMSAs = $gMSAs | `
Group-Object msDS-SupportedEncryptionTypes | `
Select-Object Count,Name,@{N="EncryptionTypesAsString";E={Get-ETypeDefinition -msDSSupportedEncryptionTypes ($_.Name) -AsString}} | `
Select-Object Count,Name,EncryptionTypesAsString,@{N="EncryptionTypesAdvice";E={Get-EncryptionTypeAdvice -msDSSupportedEncryptionTypes ($_.Name)}}

$computers= [String[]]$computers
$users= [String[]]$users
$gMSAs= [String[]]$gMSAs
<# 
[string]$split = @($computers)# -join "," #>
<# $computers.GetType().FullName
$computers[0].GetType().FullName
$computers[1].GetType().FullName
$computers[2].GetType().FullName
$computers[3].GetType().FullName #>
Write-Host "Computers:"
<# write-output $computers
write-output $users
write-output $gMSAs #>
<# write-output $split[0]
write-host $split[0]#>
foreach ($line in $computers) {
    If ($line -match $keys) {
        [string]$m = $matches.Values[0].trim()
        #get index of match
        $i = $line.IndexOf($m)
        $line.Substring(0,$i) | Write-Host -NoNewline
        $line.Substring($i) | Write-Host -ForegroundColor $keyColor.item($m)
    }
    else {
        #just write line
        Write-Host $line
    }
} 

Write-Host "Users:"
<# write-output $computers
write-output $users
write-output $gMSAs #>
<# write-output $split[0]
write-host $split[0]#>
foreach ($line in $users) {
    If ($line -match $keys) {
        [string]$m = $matches.Values[0].trim()
        #get index of match
        $i = $line.IndexOf($m)
        $line.Substring(0,$i) | Write-Host -NoNewline
        $line.Substring($i) | Write-Host -ForegroundColor $keyColor.item($m)
    }
    else {
        #just write line
        Write-Host $line
    }
} 

Write-Host "gMSAs:"
<# write-output $computers
write-output $users
write-output $gMSAs #>
<# write-output $split[0]
write-host $split[0]#>
foreach ($line in $gMSAs) {
    If ($line -match $keys) {
        [string]$m = $matches.Values[0].trim()
        #get index of match
        $i = $line.IndexOf($m)
        $line.Substring(0,$i) | Write-Host -NoNewline
        $line.Substring($i) | Write-Host -ForegroundColor $keyColor.item($m)
    }
    else {
        #just write line
        Write-Host $line
    }
} 
<# foreach ($line in $computers) {
    If ($line -match $keys) {
        [string]$m = $matches[0]
        $line.Count | Write-Host -NoNewline
        $line.Name | Write-Host -NoNewline
        $line.EncryptionTypesAsString | Write-Host -NoNewline
        $line.EncryptionTypesAdvice | Write-Host -ForegroundColor $keyColor.item($m)
    }
    else {
        #just write line
        Write-Host $line
    } 
} #>


#endregion
