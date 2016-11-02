##################################################################################
# Create ACL Sets
##################################################################################

<#
 These permission sets will be applied to folders below and will be use when setting
 permissions or verifying them.

 Each permission must include AccessRights and InheritanceFlags.  The "OWNER RIGHTS"
 is whoever owns the folder  Each hash table within the permission sets are simply 
 Splats for the Add-NTFSAccess command so you can define any options that
 are valid for that command here with the exception of Path.

 Helpful hints
  - Valid flags for InheritanceFlags are ContainerInherit, ObjectInherit or None
 
  - Most common flags for AccessRights are FullControl, Modify and Read
#>

$BaseACL = $(
    @{
        "Account"          = "BUILTIN\Administrators"
        "AccessRights"     = "FullControl"
        "InheritanceFlags" = "ContainerInherit, ObjectInherit"
    },
    @{
        "Account"          = "NT AUTHORITY\SYSTEM"
        "AccessRights"     = "FullControl"
        "InheritanceFlags" = "ContainerInherit, ObjectInherit"
    },
    @{
        "Account"          = "Domain\Domain Admins"
        "AccessRights"     = "FullControl"
        "InheritanceFlags" = "ContainerInherit, ObjectInherit"
    }
    @{
        "Account"          = "OWNER RIGHTS"
        "AccessRights"     = "FullControl"
        "InheritanceFlags" = "ContainerInherit, ObjectInherit"
    }
)

################################
# Create Folder Structure
################################
<#
This is where you define your folder structure.

Valid parameters:

 folder_template - 
    Path to the folder with {0} where you want the account name to be.  We 
    are using string templates for this.  Find out more here
    https://blogs.technet.microsoft.com/heyscriptingguy/2014/02/15/string-formatting-in-windows-powershell/ 
 
 template_var - 
    This is the ADuser value you want to use to replace the {0} above. Really
    your only two options are SamAccountName and DisplayName.

 apply_groups - 
    A list of AD groups you want the folder applied to.
  
 DisableInharitance (Optional) - 
    If this is set to true inheritance on the folder will be disabled
    and any permissions cleared

 Permissions - 
    Defines the permissions that will be assigned. If it's set to $null it's assumed that
    the folder will inherit this permissions from above.  
 
 Owner (Optional) - 
    If you want to set the owner of the folder to an a specific account set this option
    to the account you want.  If Owner is not set the script will assume the owner is
    whatever account you pass.
 
The below example will create this folder structure. 

For groups 1, 2 and 3 
|-> \\Server1\c$\test1
|       |-> Users
|           |-> <SamAccountName>
|               |-> Documents
|       |-> Staff
|           |-> <DisplayName>

For Group 10
|-> \\Server2\c$\test2
|      |-> Staff
|           |-> <SamAccountName>

For Group 9
|-> \\Server2\c$\test2
|      |-> Stu
|           |-> <SamAccountName>

#>
$Folders = @{
    'do_homedirs' = [pscustomobject]@{
        'folder_template'     = '\\Server1\c$\test1\users\{0}'
        'template_var'        = 'SamAccountName'
        'apply_groups'        = @('Group1','Group2', 'Group3')
        'Disable_Inheritance' = $true
        'acl'                 = $BaseACL
    }
    'do_homedirs_docs' = [pscustomobject]@{
        'folder_template' = '\\Server1\c$\test1\users\{0}\Documents'
        'template_var'    = 'SamAccountName'
        'apply_groups'    = @('Group1','Group2', 'Group3')
        'acl'             = $null
    }
    'do_common' = [pscustomobject]@{
        'folder_template' = '\\Server1\c$\test1\Staff\{0}'
        'template_var'    = 'DisplayName'
        'apply_groups'    = @('Group1','Group2', 'Group3')
        'acl'             = $BaseACL
    }
    'pass_homedirs_staff' = [pscustomobject]@{
        'folder_template' = '\\Server2\c$\test2\staff\{0}'
        'template_var'    = 'SamAccountName'
        'apply_groups'    = @('Group10')
        'Disable_Inheritance' = $true
        'acl'             = $BaseACL

    }
    'pass_homedirs_student' = [pscustomobject]@{
        'folder_template' = '\\Server2\c$\test2\stu\{0}'
        'template_var'    = 'SamAccountName'
        'apply_groups'    = @('Group9')
        'Disable_Inheritance' = $true
        'acl'             = $BaseACL + @(
            @{
                "Account"          = "Domain\Staff"
                "AccessRights"     = "FullControl"
                "InheritanceFlags" = "ContainerInherit, ObjectInherit"
            }
        )
    }
}


