<#
.SYNOPSIS
Uses the StructuredFoldersConfig.ps1 config to create a folder structure for a user

.DESCRIPTION
This script reads a StructuredFoldersConfig and will creat a folder structure for an
account that is passed to it.  By defalt the dynamic nameing will simply use the username
portion of the account you pass the script.  If you want it to get more complicated will 
will have to play with the code.

TO-DO
This script currently only accepts a strings with an account name but it should also be
enhanced to accept user objects.

.PARAMETER Config
Accepts the full path to a StructuredFoldersConfig file

.PARAMETER Account
Accepts an account name string (not a user object yet) in the form of <username>@<domain>

.EXAMPLE
Create-StructuredFolders -Account "domain\bsmith" -config "c:\StructuredFoldersConfig.ps1"

This will use the config located at c:\StructuredFoldersConfig.ps1 and create folders with the 
dynamic name of bsmith.
#>



[cmdletBinding()]
param(
    [parameter(Mandatory=$true,
               Position=0,
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True)]
              [Alias('UserPrincipalName')]
              [string[]]$Account,
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

    <#    
    This is the function that does most of the work.  it must be done as a function
    because it calles its self to recursivly create subfolders
    #>
    Function Create-folders{
        Param (
        $Folders,
        $name,
        $root,
        $DisableInharitance,
        $Permissions
        )

        $path = "$root\$name"

        if(!(Test-Path $path)) {
            Write-Verbose "Createing: Createing directory $path\$name"
            New-Item -Path $root -Name $name -ItemType Directory | Out-Null
        }else{
            Write-Verbose "Existing: $path\$name already exists"
        }
        if($folders -ne $null){
           foreach($sub in $folders){
                if($sub.keys -match 'Name'){
                    Create-folders -root "$root\$name" @sub
                }Else{
                    Create-folders -name $DynamicFolderName -root "$root\$name" @sub
                }
            }
        }
    }

}
process
{

    <#
    Format the name of any folder you want to dynamicly name.  This variable will be the
    name of any folder defined in the structuredfolderconfig without a name.
    #>
    if($Account -match "@"){
        $DynamicFolderName = ($Account.Split(“@”)[0]) 
    }Else{
        Write-Error "Username must be in <username>@<domain> format"
        exit
    }

    foreach($folder1 in $FolderTree) {
       
        if($folder1.keys -match 'Name'){
            Create-folders @folder1 
        }Else{
            Create-folders -name $DynamicFolderName @folder1
        }
    }
}

end
{
    # perform any final cleanup, of summary processing of pipeline input

}
