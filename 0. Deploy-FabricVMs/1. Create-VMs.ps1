$ErrorActionPreference = "Stop"

$Config = Invoke-Expression -Command (Get-Content -Path "C:\temp\CTGlobal\ConfigFiles_Gentofte\Fabric_DomainConfig.psd1" -raw)
$VMConfigs = Invoke-Expression -Command (Get-Content -Path "C:\temp\CTGlobal\ConfigFiles_Gentofte\Fabric_VMsConfig.ps1" -raw)


foreach ($vmConfig in $VMConfigs.VMs) {
    if ($vmConfig.JoinDomain -eq $true) {
        if (!(Get-VM | ? {$_.Name -eq $VMConfig.Name})) {
            .\DeployVM.ps1 -ComputerName $VMConfig.Name -AdminPassword $Config.CommonVMConfig.localAdminPassword `
                -IP $VMConfig.IP -Subnet $Config.DomainControllers[1].Subnet -GW $Config.DomainControllers[1].Gateway  `
                -DNSServer @($Config.DomainControllers[1].IPAddress, $Config.DomainControllers[0].IPAddress) `
                -DomainJoin $true -DomainName $config.DomainConfig.DomainName -DomainUsername "administrator" -DomainPassword $Config.CommonVMConfig.localAdminPassword `
                -SwitchName $Config.CommonVMConfig.VMSwitch -Vlan $Config.CommonVMConfig.FabricVlan `
                -SysPrepVHDPath $VMConfig.SysPrepVHDPath -ParentWorkdir $Config.CommonVMConfig.VMRootPath `
                -StartMemory $VMConfig.StartMemory -MinMemory $VMConfig.MinMemory -MaxMemory $VMConfig.MaxMemory
        }
    }
    else{
        if (!(Get-VM | ? {$_.Name -eq $VMConfig.Name})) {

            .\DeployVM.ps1 -ComputerName $VMConfig.Name -AdminPassword $Config.CommonVMConfig.localAdminPassword `
                -IP $VMConfig.IP -Subnet $Config.DomainControllers[1].Subnet -GW $Config.DomainControllers[1].Gateway  `
                -DNSServer @($Config.DomainControllers[1].IPAddress, $Config.DomainControllers[0].IPAddress) `
                -DomainJoin $false `
                -SwitchName $Config.CommonVMConfig.VMSwitch -Vlan $Config.CommonVMConfig.FabricVlan `
                -SysPrepVHDPath $VMConfig.SysPrepVHDPath -ParentWorkdir $Config.CommonVMConfig.VMRootPath `
                -StartMemory $VMConfig.StartMemory -MinMemory $VMConfig.MinMemory -MaxMemory $VMConfig.MaxMemory
        }
    }
}