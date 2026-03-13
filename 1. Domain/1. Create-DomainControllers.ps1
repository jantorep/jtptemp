$ErrorActionPreference = "Stop"

$Config = Invoke-Expression -Command (Get-Content -Path "C:\temp\CTGlobal\ConfigFiles_Gentofte\Fabric_DomainConfig.psd1" -raw)

#Create DC1
.\DeployVM.ps1 -ComputerName $Config.DomainControllers[0].Name -AdminPassword $Config.CommonVMConfig.localAdminPassword `
    -IP $Config.DomainControllers[0].IPAddress -Subnet $Config.DomainControllers[0].Subnet -GW $Config.DomainControllers[0].Gateway `
    -DNSServer @($Config.DomainControllers[0].IPAddress, $Config.DomainControllers[1].IPAddress) `
    -SwitchName $Config.CommonVMConfig.VMSwitch -Vlan $Config.CommonVMConfig.FabricVlan `
    -SysPrepVHDPath $Config.CommonVMConfig.SourceVHD -ParentWorkdir $Config.CommonVMConfig.VMRootPath


#region Install First DC
$password = $Config.CommonVMConfig.localAdminPassword | ConvertTo-SecureString -asPlainText -Force
$username = "Administrator"
$VMCreds = New-Object System.Management.Automation.PSCredential($username, $password)

Invoke-Command -VMName $Config.DomainControllers[0].Name -Credential $VMCreds -ArgumentList $config.DomainConfig -ScriptBlock {
    param($DomainConfig)   

    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

    Import-Module ADDSDeployment
    Install-ADDSForest -DomainName $DomainConfig.DomainName `
        -DomainNetbiosName $DomainConfig.DomainNetbiosName `
        -DomainMode WinThreshold `
        -ForestMode WinThreshold `
        -SafeModeAdministratorPassword (ConvertTo-SecureString  -String ($DomainConfig.SafeModeAdministratorPassword) -AsPlainText -Force) `
        -InstallDns:$true `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -LogPath "C:\Windows\NTDS" `
        -SysvolPath "C:\Windows\SYSVOL" `
        -NoRebootOnCompletion:$false `
        -Force:$true
}
#endregion Install First DC

#Create DC2
.\DeployVM.ps1 -ComputerName $Config.DomainControllers[1].Name -AdminPassword $Config.CommonVMConfig.localAdminPassword `
    -IP $Config.DomainControllers[1].IPAddress -Subnet $Config.DomainControllers[1].Subnet -GW $Config.DomainControllers[1].Gateway  `
    -DNSServer @($Config.DomainControllers[1].IPAddress, $Config.DomainControllers[0].IPAddress) `
    -DomainJoin $true -DomainName $config.DomainConfig.DomainName -DomainUsername "administrator" -DomainPassword $Config.CommonVMConfig.localAdminPassword `
    -SwitchName $Config.CommonVMConfig.VMSwitch -Vlan $Config.CommonVMConfig.FabricVlan `
    -SysPrepVHDPath $Config.CommonVMConfig.SourceVHD -ParentWorkdir $Config.CommonVMConfig.VMRootPath


#region Install Second DC
$password = $Config.CommonVMConfig.localAdminPassword | ConvertTo-SecureString -asPlainText -Force
$username = "$($config.DomainConfig.DomainName)\Administrator"
$VMCreds = New-Object System.Management.Automation.PSCredential($username, $password)

Invoke-Command -VMName $Config.DomainControllers[1].Name -Credential $VMCreds -ArgumentList $config.DomainConfig -ScriptBlock {
    param($DomainConfig)   

    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

    Import-Module ADDSDeployment
    Install-ADDSDomainController -DomainName $DomainConfig.DomainName `
    -SafeModeAdministratorPassword (ConvertTo-SecureString  -String ($DomainConfig.SafeModeAdministratorPassword) -AsPlainText -Force) `
    -InstallDns:$true `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -NoRebootOnCompletion:$false `
    -NoGlobalCatalog:$false `
    -Force:$true    
}
#endregion Install Second DC

#Create MGMT Worker
.\DeployVM.ps1 -ComputerName "faMGMTWorker" -AdminPassword $Config.CommonVMConfig.localAdminPassword `
    -IP 10.30.1.250 -Subnet $Config.DomainControllers[1].Subnet -GW $Config.DomainControllers[1].Gateway  `
    -DNSServer @($Config.DomainControllers[1].IPAddress, $Config.DomainControllers[0].IPAddress) `
    -DomainJoin $true -DomainName $config.DomainConfig.DomainName -DomainUsername "administrator" -DomainPassword $Config.CommonVMConfig.localAdminPassword `
    -SwitchName $Config.CommonVMConfig.VMSwitch -Vlan $Config.CommonVMConfig.FabricVlan `
    -SysPrepVHDPath C:\temp\Create-MasterVHD\VHD\WS2016_DC_GUI_1807.vhdx -ParentWorkdir $Config.CommonVMConfig.VMRootPath


Set-DnsServerScavenging -ApplyOnAllZones -ScavengingState $true -ComputerName faDC01
Set-DnsServerScavenging -ApplyOnAllZones -ScavengingState $true -ComputerName faDC02