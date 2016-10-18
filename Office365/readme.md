Setting up the Office 365 license script.

1)  Copy scripts
	Place the Update-MsolUserLicenses.ps1 and Get-MsolRecursiveGroupMember.ps1 in the same folder.
2)  Install Azure AD powershell module
	Go to https://msdn.microsoft.com/en-us/library/azure/jj151815%28v=azure.98%29.aspx#bkmk_installmodule for more information.
3)  What AD group do you want apply the license to?
	Currently the script will only accept one group as a variable but it is smart enough to understand nested groups.
	Replace the parameter $StaffGroup with the group you want to use
4)  What License do you want to use?
	Open up power shell and run get-MsolAccountSku to view your current available licenses.
	To get a list of valid licenses for your domain use these commands 

    $cred = Get-Credential
    Connect-MsolService -Credential $cred
    Get-MsolAccountSku

	Run the below command to see who is currently licensed in your organization and what license they have.
    Get-MsolUser -all | Where-Object {$_.IsLicensed -eq $true} | select DisplayName,Licenses

Notes:
*	This script is pretty simple it deals with ONE user group and ONE license.
*	All users in the group must have the same license applied or the scrip will throw an error when it is trying to remove the license.
*	The Update-MsolUserLicenses has additional documentation in the script so read that to.
*   The get-MsolRecursiveGroupMember script was origionaly written by Johan Dahlbom(johan[at]dahlbom.eu Blog: 365lab.net) and slightly modified.
 
 .SYNOPSIS
This script will add/remove o365 licenses for a selected group.

.DESCRIPTION
This script connectes to Microsofts Windows Azure Active Directory and adds licenses for
office 365 to all users that are part of the specificed AD group(and all nested groups).  
By default the script will also search for disabled groups and remove any license they are
assigned.  The script will search for all members of the specified group that don't
have a License and add one.

This script does have some issues.  It does not check what type of license is applied to 
the user it just checkes if the user is licensed.  So this script will not work if you are
moveing from one type of license to another.

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
By default we will add and remove licesnes to the approrpriate accounts.  Passing
Add, or Remove to this parmater will result in only the selected task be preformed.

.PARAMETER Group
The group to activate licenses for.

.PARAMETER AddExchange
By defoule the exchagne option of the license is disabled.  Add this switch to enable it.

.PARAMETER License
The licese string you want the script to use.  To get a list of valid licenses use these commands 

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



#>