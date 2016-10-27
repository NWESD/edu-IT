
##################################################################################
# Create Permission Sets
##################################################################################

<#
 These permission sets will be applied to folders below and will be use when setting
 permissions or verifying them.

 Each permision must include AccessRights and InheritanceFlags.  If the Account
 peramiter is not defined it is assumed that the script using this config will
 dynamicly assign the username.  Each hash table within the permission sets 
 are simply Splats for the Add-NTFSAccess command so you can define any of that
 commands options here

 Helpful hints
  - Valid flags for InheritanceFlags are ContainerInherit, ObjectInherit or None
 
  - Most common flags for AccessRights are FullControl, Modify and Read

  - The $StdPermissions set are the default permissions that are assigned any
      folder created on c:\ on a standard windows 10 system.
#>

$StdPermissions = @(
    @{
        "Account" = "BUILTIN\Administrators"
        "AccessRights" = "FullControl"
        "InheritanceFlags" = "ContainerInherit, ObjectInherit"
    },
    @{
        "Account" = "NT AUTHORITY\SYSTEM"
        "AccessRights" = "FullControl"
        "InheritanceFlags" = "ContainerInherit, ObjectInherit"
    }
    @{
        "Account" = "BUILTIN\Users"
        "AccessRights" = "ReadAndExecute, Synchronize"
        "InheritanceFlags" = "ContainerInherit, ObjectInherit"
    }
    @{
        "Account" = "NT AUTHORITY\Authenticated Users"
        "AccessRights" = "Modify, Synchronize"
        "InheritanceFlags" = "None"
    }
    @{
        "Account" = "NT AUTHORITY\Authenticated Users"
        "AccessRights" = "Delete, GenericExecute, GenericWrite, GenericRead"
        "InheritanceFlags" = "ContainerInherit, ObjectInherit"
    }
)

$UserPerms = @(
    @{
        "AccessRights" = "Modify"
        "InheritanceFlags" = "ContainerInherit, ObjectInherit"
    },
    @{
        "Account" = "Esd189\Administrators"
        "AccessRights" = "FullControl"
        "InheritanceFlags" = "ContainerInherit, ObjectInherit"
    },
    @{
        "Account" = "BUILTIN\Administrators"
        "AccessRights" = "FullControl"
        "InheritanceFlags" = "ContainerInherit, ObjectInherit"
    }    
)

################################
# Create Folder Structure
################################
<#
For this section define your folders from the bottom up.  Starting with the "deepest"
folders in your tree define each folder you would like created.  Then define their 
parent with the "folders" paramiter set like you see in below example.  If you disable
inharitance make sure you have the permissions optoin defened or your folder will have
no permissions.  You do not have to have inharitance disabled to add additional permissions

The variable $FolderTree is the only variable that scripts use from this config so you can
change any other variable name except that one!

Valid paramaters:
 Name - Name of folder. If missing it's assumed the script using this config will assigne
         a name dynamicly
 
 DisableInharitance - If this is set to true inharitance on the folder will be disabled
                        and any permissions cleared

 Root - Only used on the top folder and defines where the folder tree starts
 
 Folders - Defines the child folders for that directory
 
 Permissions - Defines the permissions that will be assigned/verified. If missing it's 
                assumed that the folder will inharit this permisions from above.  
 
 Owner - If you want to set the owner of the folder to an account determined by a script
          set it equal tp "Dynamic" as the Owner.  If you specify a spcific account set 
          owner to equal the acount name in the "<domain>\<username>" format 


The below example will create this folder structure.

|-> c:\testing
|   |-> Users
|       |-> <username> (name dynamicly assigned)
|           |-> Desktop
|           |-> Backup
|-> c:\test2
|   |-> <username> (name dynamicly assigned)
#>

$Desktop = @{
    "Name" = "Desktop"
    "DisableInharitance" = $false
}
$Backup = @{
    "Name" = "Backup"
    "DisableInharitance" = $false
}

$UserHome = @{
    "DisableInharitance" = $true
    "Permissions" = $UserPerms
    "Owner" = "Dynamic"
    "Folders" = @(
        $Desktop
        $Backup
    )
}

$userstree = @{
    "Name" = "Users"
    "DisableInharitance" = $True
    "Root" = "c:\testing"
    "Folders" = @(
        $UserHome
    )
} 

$userstree2 =@{
    "DisableInharitance" = $false
    "Root" = "c:\test2"
}

#########################################
# Creat the master object
#########################################

$FolderTree = @(
    $userstree2
    $userstree
)



