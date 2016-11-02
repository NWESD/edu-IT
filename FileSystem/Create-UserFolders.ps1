<#
.SYNOPSIS
This script will create a user’s folders based on group membership and a config file

.DESCRIPTION
This script accepts two mandatory arguments and AD account name or object and a config
file.  The script will then quarry AD and then create any necessary folders based on group
membership.  

Regardless of whether the script creates the folder or not the permissions will get reset 
according to the config file.  This is intended because the assumption is that this is 
run on a new user accounts.  Look at the Check-UserFolderACL or Reset-UserFolderACL if
you want different behavior. 

This script requiers the ActiveDirectory and NTFSSecurity powershell Modules.  To install:

Find-Module ActiveDirectory | Install-Module
Find-Module NTFSSecurity | Install-Module

.PARAMETER Config
Accepts the full path to a StructuredFoldersConfig file

.PARAMETER Account
Accepts an account name string in the form of <username> or an ADuser object

.EXAMPLE
Create-UserFolders -Account "bsmith" -config "c:\FoldersConfig.ps1"

This will use the config located at c:\FoldersConfig.ps1 and create folders 
for the bsmith account.

.EXAMPLE
'bsmith','fstone','tlee' | Create-UserFolders -config "c:\FoldersConfig.ps1"

This will use the config located at c:\StructuredFoldersConfig.ps1 and create folders
for the three accounts piped to the script.

.EXAMPLE
Get-ADGroupMember "_GRP_Remote_Site_Staff" -Recursive | Get-ADUser | Create-UserFolders -config "c:\FoldersConfig.ps1"

This will create folders for every user in the _GRP_Remote_Site_Staff group. 
#>

[cmdletBinding()]
param(
    [parameter(Mandatory=$true,
               Position=0,
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True)]
              $Account,
    [parameter(Mandatory=$true)]
             [string]$Config
)


begin
{
    # Comments should be on their own line.
    Set-StrictMode -Version Latest

    # Kill script if anything fails (by default)
    $ErrorActionPreference = "Stop"    
    
    # Grab the config
    if (test-path $config) {
        . $Config
    }else{
        Write-Error "Can not access $Config"
        exit
    }

    Import-Module ActiveDirectory -Verbose:$false
    Import-Module NTFSSecurity -Verbose:$false

    try{
        Enable-Privileges -Verbose:$false
    }catch{
        write-error "This script must be run as an administrator"
    }
}
process
{
    switch($Account.gettype().name){
        "ADUser"      {$User = ($Account |Get-ADUser -Properties MemberOf, DisplayName)}
        "string"      {$User = ($Account |Get-ADUser -Properties MemberOf, DisplayName)}
        default {write-error "only strings and ADUser objects"; exit}
    }

    Write-Verbose "------------------------"
    Write-Verbose "- User: $($User.SamAccountName)" -Verbose
    Write-Verbose "------------------------"

    $Groups = ($User.MemberOf | Get-ADGroup).Name   

    foreach ($folder in $folders.Keys){
        
        # Iterate through the groups that the user is a member of check if the current folder applies to them
        $group_intersect = $Folders[$Folder].apply_groups | Where-Object {$Groups -contains $_ }
        
        # If the folder applies then check/create the folders and reset the permissions
        If ($group_intersect) {
            
            # render the full path and folder name
            $renderedfolder = $Folders[$Folder].folder_template -f $user.($Folders[$Folder].template_var)

            # test the folder and if it's not there create it
            if(!(Test-Path $renderedfolder)){
                Write-Verbose "Create Folder: $renderedfolder" -Verbose
                New-Item $renderedfolder -ItemType Directory | Out-Null
            }else{
                Write-verbose "Existing Folder: $renderedfolder already created" -Verbose
            }
            
            # Set Owner of the folder
            if($Folders[$Folder].psobject.Properties.name -match 'owner'){
                Set-NTFSOwner -Path $renderedfolder -Account $folders[$folder].owner -Verbose:$false

            }else{
                Set-NTFSOwner -Path $renderedfolder -Account $User.UserPrincipalName -Verbose:$false

            }

            # Disable Inheritance if it is set in the config
            if($Folders[$Folder].psobject.Properties.name -match 'Disable_Inheritance'){
                Write-Verbose "Disableing inheritance on $renderedfolder" 
                Disable-NTFSAccessInheritance -Path $renderedfolder -Verbose:$false
            }else{
                Enable-NTFSAccessInheritance -Path $renderedfolder -Verbose:$false
            }

            # Set/reset the permistions on the folders regardless of weather they were created or not.
            Clear-NTFSAccess -Path $renderedfolder -Verbose:$false
            foreach ($acl in $Folders[$Folder].acl) {
                # 'OWNER RIGHTS' is a valid windows 2008r2+ trustee,
                # but lets use the actual user object instead.
                If ('OWNER RIGHTS' -eq $acl.Account) {
                    Add-NTFSAccess -Path $renderedfolder `
                                   -Account $User.UserPrincipalName `
                                   -InheritanceFlags $acl.InheritanceFlags `
                                   -AccessRights $acl.AccessRights `
                                   -Verbose:$false
                    continue 
                }
                Write-Verbose "Account:    $($acl.Account) Given: $($acl.AccessRights)"
                Add-NTFSAccess -Path $renderedfolder @acl -Verbose:$false
            }
        } 
    }
}

end
{

    Disable-Privileges -Verbose:$false
}
