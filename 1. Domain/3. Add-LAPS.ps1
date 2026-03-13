$ErrorActionPreference = "Stop"

$Config = Invoke-Expression -Command (Get-Content -Path "C:\temp\Fabric_DomainConfig.psd1" -raw)
$LAPSPath = "C:\temp\LAPS.x64.msi"
$LAPSGPOPath = 'C:\temp\CTGlobal\GPOs\Computer - LAPS'
$LAPSAdmins = "fabric.gentofte.dk\LAPSAdmins"
$OUname = "Fabric"

#Install LAPS on Domain Controller
Start-Process msiexec.exe -Wait -ArgumentList "/i $LAPSPath ADDLOCAL=CSE,Management.UI,Management.PS,Management.ADMX /quiet /norestart"


#Updating the Schema using PowerShell
Import-Module AdmPwd.PS
Update-AdmPwdADSchema -Verbose

#Watching out for Extended Rights
Get-ADOrganizationalUnit -Filter *|Find-AdmPwdExtendedRights -PipelineVariable OU |ForEach {
    $_.ExtendedRightHolders|ForEach {
        [pscustomobject]@{
            OU     = $Ou.ObjectDN
            Object = $_
        }
    }
}

#Import GPO
$LAPSShare = "\\$((Get-WmiObject Win32_ComputerSystem).Domain)\NETLOGON\Software\LAPS"
if(!(Test-Path $LAPSShare)){
    mkdir $LAPSShare
}
Copy-Item $LAPSPath -Destination $LAPSShare

Import-GPO -Path $LAPSGPOPath -BackupGpoName 'Computer - LAPS' -TargetName 'Computer - LAPS' -CreateIfNeeded

$LAPSGpo = Get-GPO -Name 'Computer - LAPS'
$LAPSGpo | New-GPLink -Target "OU=Fabric,$($config.DomainConfig.RootDN)" -LinkEnabled Yes

#   !!!!!!!!!!!!!!!!   #
#   Validate the GPO   #
#   !!!!!!!!!!!!!!!!   #


#Configure Permissions for the Computer to Update its Attributes
Set-AdmPwdComputerSelfPermission -Identity $OUname -Verbose

#Granting Rights to User or Groups to Read and Reset the Password
Set-AdmPwdResetPasswordPermission -Identity $OUname -AllowedPrincipals $LAPSAdmins -Verbose
Set-AdmPwdReadPasswordPermission -Identity $OUname -AllowedPrincipals $LAPSAdmins -Verbose

#Change Password policy if need
#Change Password policy if need
#Change Password policy if need

#Check LAPS
Invoke-GPUpdate -Computer testVM01 -Verbose
Get-ADComputer -Filter * -Properties ms-MCS-AdmPwd,ms-MCS-AdmPwdExpirationTime | ft DNSHostname,ms-MCS-AdmPwd,ms-MCS-AdmPwdExpirationTime


