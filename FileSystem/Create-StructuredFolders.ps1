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
Mandatory=$true
#>



[cmdletBinding()]
param(
    [parameter(Mandatory=$true,
               Position=0,
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True)]
              [Alias("UserPrincipalName")]
              [string]$Account,
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


    $Dirs = New-Object System.Collections.ArrayList

    # Feed the config into the arrray so we can process it.
    foreach ($Tree in $FolderTree){
        $Dirs.Add($Tree) | Out-Null
    }

    # Process the folders to create.
    while ( $Dirs.Count -ge 0 ){
        $ProcessDirs = $Dirs.Clone()
        if ($ProcessDirs.count -eq 0) {
            break
        }
        $ProcessDirs | ForEach-Object {
            # Give an error if the config does not have a root option set for the first folder of the tree.
            if(!($_.keys -match 'Root')){
                Write-Error "The root folder of each tree should have the ROOT variable defined!  Check your configuration!"
                exit
            }
            # Check to see if we need to assign the Dynamic folder name or use the one in the config.
            if(!($_.keys -match 'Name')){
                $Folder = $_.root + "\" +$DynamicFolderName
                $folderName = $DynamicFolderName
            }Else{
                $Folder = $_.root + "\" +$_.Name
                $FolderName = $_.name
            }
            
            #Check to see if folder already exists and if not create it
            if(Test-Path $folder){
                Write-Verbose "Folder $folder already created"
            }else{
                Write-Verbose "Createing Folder: $Folder"
                New-Item -Path $_.root -Name $FolderName -ItemType Directory | Out-Null
            }
            
            # Check to see if their are subfolders to create and add the to the list to process
            If($_.keys -match "Folders"){
                $_.folders | ForEach-Object{
                    $_.root = $Folder
                    $Dirs.add($_)| Out-Null
                }
            }
            $Dirs.Remove($_)
        }
    }
}

end
{
    # perform any final cleanup, of summary processing of pipeline input

}
