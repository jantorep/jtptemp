
$GPOItems = Get-ChildItem -Path C:\temp\CTGlobal\GPOs

$GPOItems = $GPOItems | Out-GridView -PassThru

foreach($GPOItem in $GPOItems){
    Import-GPO -Path $GPOItem.FullName -BackupGpoName $GPOItem.Name -TargetName $GPOItem.Name -CreateIfNeeded
}


Get-GPO -Name 'Computer - Windows Update - Every Wednesday 0300' | New-GPLink -Target "OU=Servers,OU=Fabric,$($config.DomainConfig.RootDN)" -LinkEnabled Yes
Get-GPO -Name 'Computer - Windows Update - Every Monday 0300' | New-GPLink -Target "OU=Servers,OU=Fabric,$($config.DomainConfig.RootDN)" -LinkEnabled Yes
Get-GPO -Name 'Computer - LocalAdmins' | New-GPLink -Target "OU=Servers,OU=Fabric,$($config.DomainConfig.RootDN)" -LinkEnabled Yes
Get-GPO -Name 'Computer - LAPS' | New-GPLink -Target "OU=Servers,OU=Fabric,$($config.DomainConfig.RootDN)" -LinkEnabled Yes
Get-GPO -Name 'Computer - Defender Settings' | New-GPLink -Target "OU=Servers,OU=Fabric,$($config.DomainConfig.RootDN)" -LinkEnabled Yes
Get-GPO -Name 'Computer - Defender Hyper-V' | New-GPLink -Target "OU=Servers,OU=Fabric,$($config.DomainConfig.RootDN)" -LinkEnabled Yes
Get-GPO -Name 'Computer - Default Settings' | New-GPLink -Target "OU=Servers,OU=Fabric,$($config.DomainConfig.RootDN)" -LinkEnabled Yes
Get-GPO -Name 'Computer - Certificate Enrollment' | New-GPLink -Target "OU=Servers,OU=Fabric,$($config.DomainConfig.RootDN)" -LinkEnabled Yes
#MORE MISSING