$ErrorActionPreference = "Stop"

$DHCPConfig = Invoke-Expression -Command (Get-Content -Path "C:\temp\CTGlobal\ConfigFiles_Gentofte\Fabric_DHCPConfig.psd1" -raw )


$Server1 = $DHCPConfig.DHCPServers[0].Name
$Server2 = $DHCPConfig.DHCPServers[1].Name


Install-WindowsFeature DHCP -IncludeManagementTools -ComputerName $Server1
Install-WindowsFeature DHCP -IncludeManagementTools -ComputerName $Server2
    
#Create security Groups   
Invoke-Command -ComputerName $Server1, $Server2 -ScriptBlock {
    netsh dhcp add securitygroups
    Restart-service dhcpserver
}


#Authorize
$Address = Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred -SuffixOrigin Manual -CimSession $Server1
$FQDN = (Get-CimInstance win32_computersystem -CimSession $Server1).DNSHostName + "." + (Get-CimInstance win32_computersystem -CimSession $Server1).Domain
Add-DhcpServerInDC -DnsName $FQDN -IPAddress $Address.IPAddress
$Address = Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred -SuffixOrigin Manual -CimSession $Server2
$FQDN = (Get-CimInstance win32_computersystem -CimSession $Server2).DNSHostName + "." + (Get-CimInstance win32_computersystem -CimSession $Server2).Domain
Add-DhcpServerInDC -DnsName $FQDN -IPAddress $Address.IPAddress
Get-DhcpServerInDC

#Notify server manager task completed
Invoke-Command -ComputerName $Server1, $Server2 -ScriptBlock {
    Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2
}

#Add Failover Relationship
Add-DhcpServerv4Failover -ComputerName $Server1 -Name "$Server1-$Server2-Failover" -PartnerServer $Server2 -SharedSecret "9f7UMMtxTmGyKyzwDV5YJ" -Confirm:$false


#Create Scopes
foreach ($Scope in $DHCPConfig.Scopes) {
    if (!(Get-DhcpServerv4Scope -ComputerName $Server1 | ? {$_.Name -eq $Scope.Name})) {
        Add-DhcpServerv4Scope -Name $Scope.Name -StartRange $Scope.StartRange -EndRange $Scope.EndRange -SubnetMask $Scope.SubnetMask -State Active -ComputerName $Server1
        $ScopeObject = Get-DhcpServerv4Scope -ComputerName $Server1 | ? {$_.Name -eq $Scope.Name}
        Set-DhcpServerv4OptionValue -OptionID 3 -Value $Scope.DefaultGW -ScopeID $ScopeObject.ScopeId -ComputerName $Server1
        Set-DhcpServerv4OptionValue -DnsDomain $Scope.DNSDomain -DnsServer $Scope.DNSServers -ScopeID $ScopeObject.ScopeId -ComputerName $Server1
        
        #Create failover relationship
        Add-DhcpServerv4FailoverScope -ComputerName $Server1 -Name "$Server1-$Server2-Failover" -ScopeId $ScopeObject.ScopeId
    }
}