<#
.SYNOPSIS
a brief explanation of what the script or function does.

.DESCRIPTION
a more detailed explanation of what the script or function does.

.PARAMETER [ParameterName]
Description of parameter.  Add one of these for each parameter.

.EXAMPLE
an example of how to use the script or function. You can have multiple .EXAMPLE sections if you want to provide
more than one example.
#>

[cmdletBinding()]
param()

begin
{
    # Comments should be on their own line.
    Set-StrictMode -Version Latest


    # Kill script if anything fails (by default)
    $ErrorActionPreference = "Stop" 

    
    Import-Module ActiveDirectory -Verbose:$false
    Import-Module PSCX -Verbose:$false

    # Set the neassary special permistions needed for playing with ACLs
	#Necessary to set Owner Permissions
	Set-Privilege (new-object Pscx.Interop.TokenPrivilege "SeRestorePrivilege", $true) 
	#Necessary to bypass Traverse Checking
	Set-Privilege (new-object Pscx.Interop.TokenPrivilege "SeBackupPrivilege", $true) 
	#Necessary to override FilePermissions & take Ownership
	Set-Privilege (new-object Pscx.Interop.TokenPrivilege "SeTakeOwnershipPrivilege", $true)




Function CheckACE([string]$Path, [string]$Trustee, [string]$Mask)
{
	$acl = get-acl $Path
	foreach ($i in $acl.Access)
	{
		if (($i.FileSystemRights -match $Mask) -and`
			($i.IdentityReference -match "$Trustee"))
		{
			#$i.IdentityReference
			#$i.FileSystemRights
			return $TRUE
		}
	}
}

Function AddAclRule([string]$Account, [string]$Mask)
{
	$inheritance=[System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
	$propagation=[System.Security.AccessControl.PropagationFlags]::None
	$allowdeny=[System.Security.AccessControl.AccessControlType]::Allow
	$user1 = [System.Security.Principal.NTAccount]($Account)
	$rights=[System.Security.AccessControl.FileSystemRights]::$mask
	$dirACE=New-Object System.Security.AccessControl.FileSystemAccessRule($user1,$rights,$inheritance,$propagation,$allowdeny)
	return $dirACE
}

Function AddAclRuleSpecial([string]$Account)
{
	$inheritance=[System.Security.AccessControl.InheritanceFlags]"ContainerInherit,ObjectInherit"
	$propagation=[System.Security.AccessControl.PropagationFlags]::None
	$allowdeny=[System.Security.AccessControl.AccessControlType]::Allow

	$user1 = [System.Security.Principal.NTAccount]($Account)
	$dirACE=$acl.AccessRuleFactory($user1,268435456,$isinherited,$inheritance,$propagation,$allowdeny)
	#$dirACE=New-Object System.Security.AccessControl.FileSystemAccessRule ($account,$rights,$inheritance,$propagation,$allowdeny)
	return $dirACE
}

Function ResetPerms ([string]$HomePath)
{
	$acl = Get-Acl $HomePath
	if ($acl.AreAccessRulesProtected) 
	{ 
		$acl.Access | % {$acl.purgeaccessrules($_.IdentityReference)} 
		return $acl
	}
	else
	{
		$isProtected = $true 
		$preserveInheritance = $false
		$acl.SetAccessRuleProtection($isProtected, $preserveInheritance) 
		return $acl
	}  
}

Function ResetSubItemPerms ([string]$HomePath)
{
	# Build the ACLs that we are going to apply
	$aclDir = resetperms $HomePath
	$aclDir.SetAccessRuleProtection($false,$false)
	$aclFile = New-Object System.Security.AccessControl.fileSecurity
	$aclFile.SetOwner([System.Security.Principal.NTAccount] $acldir.Owner)
	$aclFile.SetGroup([System.Security.Principal.NTAccount] $acldir.Group)
	$aclFile.SetAccessRuleProtection($false,$false)

	$subItems = @(Get-ChildItem -LiteralPath $HomePath -Recurse –ErrorAction SilentlyContinue)            
	ForEach ($item in $subItems)
	{
		if ($item.PSIsContainer)
		{
			$folderpath = $item.fullname
			Set-Acl -aclobject $acldir -Path $item.fullname
			write-host "Perms reset on $folderpath" -f "yellow"
		}
		Else
		{
			Set-Acl -aclobject $aclfile -Path $item.fullname
		}
	}
}

}

process
{
    # Main body of program, handles any pipeline input
}

end
{
    # perform any final cleanup, of summary processing of pipeline input
}
