<#
.SYNOPSIS
Checks to see if a user has a specific level of access to a file system item. 

.DESCRIPTION
This script checks to see if a user has a specific level of access to a file system item. This script is 
really specific.  It only checks if the mask matches what is in the permissions value.  It is not smart
enough to realize that “full Control” has Write access. If someone wants to improve this great but please
provide the option for a strict option because sometimes I want someone to only have read access.

The script will return TRUE of the Trustee has the specified access.

.PARAMETER Path
The path to the file or folder you want to check

.PARAMETER Trustee
Name of the user you want to check.  You will need to escape any symbols.  For example, you “bsmith” will
work fine but if you try “domain\bsmith” it will not work.  To escape a symbol use the backslash (\)  so
“domain\\bsmith” would be fine.  

.PARAMETER Mask
The is the level of access you want to test for.  Most commonly you will want to look for FullControl, Modify,
or Read but there are a whole host of options which you can find at 

https://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights%28v=vs.110%29.aspx

Currently this argument takes any string you give it but probably should have some validation on it.


.EXAMPLE
Check-Perms -path "c:\users\bob" -Trustee "bsmith" -Mask "FullControl"

This will return true if bsmith has full control of c:\users\bob. 
#>


[cmdletBinding()]
param(
    [parameter(Mandatory=$true)]
        [string]$Path,
    [parameter(Mandatory=$true)]
        [string]$Trustee,
    [parameter(Mandatory=$true)]
        [string]$Mask
)



begin
{
    
    # Comments should be on their own line.
    Set-StrictMode -Version Latest

    # Kill script if anything fails (by default)
    $ErrorActionPreference = "Stop"
}
process
{
    Write-Verbose "Testing $path to see if $trustee has $mask access"
    if (Resolve-Path $Path)
    {
	    $acl = get-acl $Path
	    foreach ($i in $acl.Access)
	    {
		    # Write-Verbose $i.IdentityReference
		    # Write-Verbose $i.FileSystemRights
        
            if (($i.FileSystemRights -match $Mask) -and`
			    ($i.IdentityReference -match "$Trustee"))
		    {
			    return $TRUE
		    }
	    }
    }
}



