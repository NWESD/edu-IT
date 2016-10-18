<#
.SYNOPSIS
    Get Azure AD group members recurssively
.EXAMPLE
    .\Get-MsolRecursiveGroupMember -ObjectId  6d34ab03-301c-4f3a-8436-98f873ec121a -Recursive
.EXAMPLE
    .\Get-MsolRecursiveGroupMember -SearchString "Office 365 E5"
.NOTES

#>

param(
[parameter(ParameterSetName='ObjectId',
           Mandatory=$true)]
          [string]$ObjectId,
[parameter(ParameterSetName='SearchString',
           Mandatory=$true)]
          [string]$SearchString
)

$MSOLAccountSku = Get-MsolAccountSku -ErrorAction Ignore -WarningAction Ignore
if (-not($MSOLAccountSku)) {
    throw "Not connected to Azure AD, run Connect-MsolService"
}

# Get the object of the group if when we
# have the -SearchString param
If ('SearchString' -eq $PsCmdlet.ParameterSetName) {
    $ObjectId = (Get-MsolGroup -SearchString $SearchString).ObjectId
}

# verify that we have a valid group
If (-not(Get-MsolGroup -ObjectId $ObjectId)) {
    throw "Unable to load group"
}

# Groups list of groups to be processed.
# we are using a collection for stack based recurssion
$Groups=New-Object System.Collections.ArrayList
$Groups.Add($ObjectId) | Out-Null
# hash of all the members
$GroupMember=@{}

While ( $Groups.Count -ge 0 ) {
    $ProcessGroups = $Groups.Clone()
    if ($ProcessGroups.Count -eq 0) { break }
    $ProcessGroups | Foreach-Object {
        Get-MsolGroupMember -GroupObjectId $_ `
                            -MemberObjectTypes Group | Foreach-Object {
            $Groups.Add($_.ObjectId) | Out-Null
        }
        Get-MsolGroupMember -GroupObjectId $_ -MemberObjectTypes User | Foreach-Object {
            $GroupMember[$_.ObjectId] = `
                New-Object PSObject -Property @{"ObjectId" = $_.ObjectId;
                                                "DisplayName" = $_.DisplayName;
                                                "EmailAddress" = $_.EmailAddress}
        }
        $Groups.Remove($_) | Out-Null
    }
}
$GroupMember.GetEnumerator() | Foreach-Object {$_.Value}
