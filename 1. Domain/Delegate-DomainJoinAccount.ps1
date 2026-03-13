param(
    $AccountName,
    $TopDN)

# Get local environment variables
Import-Module activedirectory
$rootDSE = Get-ADRootDSE
$domain = Get-ADDomain

##############################################
# Delegate the rights to the SCCM Domain Join account on the "Computers" container

Set-Location ad:
# Create a hashtable to the the GUID value of each schema class attribute
$guidmap = @{}
Get-ADObject -SearchBase ($rootDSE.schemaNamingContext) -LDAPFilter `
    "(schemaidguid=*)" -Properties lDAPDisplayName, schemaIDGUID | % {$guidmap[$_.lDAPDisplayName] = [System.GUID]$_.schemaIDGUID}

# Create a hashtable to store the GUID value of each extended right in the forest
$extendedrightsmap = @{}
Get-ADObject -SearchBase ($rootDSE.configurationNamingContext) -LDAPFilter `
    "(&(objectclass=controlAccessRight)(rightsguid=*))" -Properties displayName, rightsGuid | % {$extendedrightsmap[$_.displayName] = [System.GUID]$_.rightsGuid}

# Get the target objects on which we need to grand access, namely the default "Computers" container and the project related Organizational Unit.
# The example here is the "Computers" container, but the object can be any Organizational Unit as well
$container = Get-ADObject -Identity $TopDN

# Get the SID values of the Domain Join account
$user = New-Object System.Security.Principal.SecurityIdentifier (Get-ADUser $AccountName).SID

# Get the current DACL on the target AD Objects
$acl1 = Get-ACL -Path ($container.DistinguishedName)

# Grant the rights on the "Computers" container
$acl1.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user, "CreateChild", "Allow", $guidmap["computer"], "All"))
$acl1.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user, "DeleteChild", "Allow", $guidmap["computer"], "All"))
$acl1.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user, "ReadProperty", "Allow", "Descendents", $guidmap["computer"]))
$acl1.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user, "WriteProperty", "Allow", "Descendents", $guidmap["computer"]))
$acl1.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user, "ReadControl", "Allow", "Descendents", $guidmap["computer"]))
$acl1.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user, "WriteDacl", "Allow", "Descendents", $guidmap["computer"]))
$acl1.AddAccessRule((New-Object System.DirectoryServices.ExtendedRightAccessRule $user, "Allow", $extendedrightsmap["Reset Password"], "Descendents", $guidmap["computer"]))
$acl1.AddAccessRule((New-Object System.DirectoryServices.ExtendedRightAccessRule $user, "Allow", $extendedrightsmap["Change Password"], "Descendents", $guidmap["computer"]))
$acl1.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user, "Self", "Allow", $extendedrightsmap["Validated write to DNS host name"], "Descendents", $guidmap["computer"]))
$acl1.AddAccessRule((New-Object System.DirectoryServices.ActiveDirectoryAccessRule $user, "Self", "Allow", $extendedrightsmap["Validated write to service principal name"], "Descendents", $guidmap["computer"]))

# Re-apply the modified DACL to the target objects
Set-ACL -AclObject $acl1 -Path ("AD:\" + ($container.DistinguishedName))
#endregion Delegate DomainJoin Account