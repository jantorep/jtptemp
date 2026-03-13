$ErrorActionPreference = "Stop"

$Config = Invoke-Expression -Command (Get-Content -Path "C:\temp\CTGlobal\ConfigFiles_Gentofte\Fabric_DomainConfig.psd1" -raw )



#region Create OUs
$OUs = $config.DomainConfig.OUs
$RootDN = $Config.DomainConfig.RootDN
foreach($OU in $OUs){
    if(!(Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OU,$RootDN'" -ErrorAction SilentlyContinue)){
        Write-Host "Creating OU $OU"
        New-ADOrganizationalUnit -Name $OU.Split(',', 2)[0].replace("OU=",'') -Path ($OU.Split(',', 2)[1] + ',' + $RootDN ).TrimStart(',')
    }
}
#endregion

#region Create Users
$Users = $config.DomainConfig.Users
foreach($User in $Users){
    if(!(Get-ADUser -Filter "SamAccountName -eq '$($user.Name)'" -ErrorAction SilentlyContinue)){
        Write-Host "Creating User $($user.name)"
        New-ADUser -Name $User.Name -AccountPassword (ConvertTo-SecureString -String $User.AccountPassword -AsPlainText -Force) `
        -Description $User.Description -Path ($user.Path+ ',' + $RootDN ).TrimStart(',') -PasswordNeverExpires $user.PasswordNeverExpires -ChangePasswordAtLogon $user.ChangePasswordAtLogon `
        -CannotChangePassword $user.CannotChangePassword -Enabled $User.Enabled
    }
}
#endregion

#region Create Groups
$Groups = $config.DomainConfig.Groups
foreach($Group in $Groups){
    if(!(Get-ADGroup -Filter "Name -eq '$($Group.Name)'" -ErrorAction SilentlyContinue)){
        Write-Host "Creating Group $($Group.name)"
        $GroupObject = New-ADGroup -Name $Group.Name -Description $Group.Description -GroupCategory $Group.GroupCategory `
        -GroupScope $Group.GroupScope -Path ($Group.Path+ ',' + $RootDN ).TrimStart(',') -PassThru
    }
    else{
        $GroupObject = Get-ADGroup -Filter "Name -eq '$($Group.Name)'"
    }
    if($group.Members){
        $GroupObject | Add-ADGroupMember -Members $Group.Members
    }
}
#endregion

#region Change default OUs
redircmp "$($config.DomainConfig.DefaultComputerOU),$($config.DomainConfig.RootDN)"
redirusr "$($config.DomainConfig.DefaultUserOU),$($config.DomainConfig.RootDN)"
#endregion Change default OUs


#Assign permissons to domain
.\Create-DomainJoinAccount.ps1 -AccountName 'svcDomainJoin' -TopDN "OU=Servers,OU=FABRIC,DC=fabric,DC=gentofte,DC=dk"