﻿<#
.SYNOPSIS
This script will add/remove o365 licenses for a selected group.

.DESCRIPTION
This script connects to Microsoft’s Windows Azure Active Directory and adds licenses for
office 365 to all users that are part of the specified AD group(and all nested groups).  
By default the script will also search for disabled groups and remove any license they are
assigned.  The script will search for all members of the specified group that don't
have a License and add one.

This script does have some issues.  It does not check what type of license is applied to 
the user it just checks if the user is licensed.  So this script will not work if you are
moving from one type of license to another.

To get a list of valid licenses for your domain use these commands 

$cred = Get-Credential
Connect-MsolService -Credential $cred
Get-MsolAccountSku

.PARAMETER CredentialFile
Allows you to use a set of credentials stored in a file that was created like this.

    Get-Credential | Export-Clixml MSOL_credential.xml

.PARAMETER Credential
Accept a [System.Management.Automation.PSCredential] directly, so the script can still
be used by people with valid credentials that don't have a saved file

.PARAMETER Operation
By default we will Add licenses to the appropriate accounts.  Passing Both, Add, or Remove
to this parameter will result in only the selected task be preformed.

.PARAMETER Group
The group to activate licenses for.

.PARAMETER DisabledPlans
If you want to disable any of the individual plans for a license pass a comma separated list to this variable.
for example "EXCHANGE_S_STANDARD", "YAMMER_EDU"

To get a list of available plans for a given license run this command:
  (Get-MsolAccountSku | where {$_.AccountSkuId -eq '<AccountSkuId>'}).ServiceStatus

.PARAMETER License
The license string you want the script to use.  To get a list of valid licenses use these commands 

$cred = Get-Credential
Connect-MsolService -Credential $cred
Get-MsolAccountSku

.EXAMPLE

This pattern is what we would probably use in a scheduled task

    .\Update-MsolUserLicenses.ps1 -CredentialFile C:\Users\username\Documents\MSOL_credential.xml -License "something" -Group "somegroup"

.EXAMPLE

This method is useful when running interactively.

    $creds = Get-Credential
    .\Update-MsolUserLicenses.ps1 -Credential $creds -License "something" -Group "somegroup" -verbose 

.EXAMPLE

An example of disabling the exchange plan for a license 
 .\Update-MsolUserLicenses.ps1 -Credential $creds -License "something" -Group "somegroup" -DisabledPlans "EXCHANGE_S_STANDARD" -verbose 

#> 



[cmdletBinding()]
param(
    [parameter(ParameterSetName='CredVar',
               Mandatory=$true)]
              [pscredential]
              [System.Management.Automation.CredentialAttribute()]
              $Credential,
    [parameter(ParameterSetName='CredFile',
               Mandatory=$true)]
              [string]$CredentialFile,
    [ValidateSet('Both','Add','Remove')] 
				[string]$Operation='Add',
    [parameter(Mandatory=$true)]
			   [string]$Group,
    [parameter(Mandatory=$true)]
			   [string]$License,
               [array]$DisabledPlans		   
)
Set-StrictMode -Version Latest

# Get Credentials when CredentialFile was used.
If ('CredFile' -eq $PsCmdlet.ParameterSetName) {
    $Credential = Import-Clixml $CredentialFile
    If ('System.Management.Automation.PSCredential' -ne
        ($Credential).GetType().FullName) {
        throw "The loaded object must be a [System.Management.Automation.PSCredential]"
    }
}

#  Check to see if MSOnline moduel is loaded and if not load it or error out.
if (Get-Module -Name MSOnline){
    Write-Verbose "MSOnline Module is loaded"
}elseif (Get-Module -ListAvailable -Name MSOnline){
    Write-Verbose "MSOnline Module is not loaded but is avalible."
    Write-Verbose "Loading Module..."
    Import-Module MSOnline
}else{
    throw "MSOnline powershell module not avalible.  Please install module before continuing"
}

# Check to see if you are connected to MSOnline and if not connect
$MSOLAccountSku = Get-MsolAccountSku -ErrorAction Ignore -WarningAction Ignore
if (-not($MSOLAccountSku)) {
    Write-Verbose "Authenticating to the MSOL"
    Connect-MsolService -Credential $Credential
}

If ($Operation -eq 'Both' -or $Operation -eq 'Remove') {
    #  Search for users that are licensed but have disabled accounts and remove their licenses
    Write-Verbose "Removing licenses for inactive staff"
    $BadUsers = Get-MsolUser -MaxResults 100 | Where-Object {$_.IsLicensed -eq $true -and $_.BlockCredential -eq $true}
    Foreach ($user in $BadUsers){
        ForEach ($lic in $user.Licenses){
            Set-MsolUserLicense -UserPrincipalName $user.UserPrincipalName -RemoveLicenses  $lic.AccountSkuId
        }
        Write-Verbose "$($user.DisplayName) - License removed" 
    }

}



If ($Operation -eq 'Both' -or $Operation -eq 'Add') {
    Write-Verbose "Adding licenses for staff"

    #  Set the License options We want.  This command sets the we want to use.  If the addexchagne optons is set
    #  we will also enable the exchagne portion of the license if not we will disable "Exchange Online ‎(Plan 1)‎" 
    if ($DisabledPlans){
        $options = New-MsolLicenseOptions -AccountSkuId $License -DisabledPlans $DisabledPlans
        Write-Verbose "Plans Disabled: $DisabledPlans"
    }else{
        $options = New-MsolLicenseOptions -AccountSkuId $License 
    }

    & "$PSScriptRoot\.\Get-MsolRecursiveGroupMember" -SearchString $Group | Get-MsolUser | `
        Where-Object {$_.IsLicensed -eq $false -and $_.BlockCredential -eq $false} | Foreach-Object {

        Write-Verbose "Processing $($_.UserPrincipalName) $($_.DisplayName)"

        #  The Usage location must be set before a license can be applied.
        Set-MsolUser -ObjectId $_.ObjectId -UsageLocation US
        #  adds the license
        Set-MsolUserLicense -ObjectId $_.ObjectId `
            -AddLicenses $License -LicenseOptions $options

        }
}
