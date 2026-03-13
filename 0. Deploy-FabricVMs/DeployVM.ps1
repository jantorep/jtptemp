[CmdletBinding()]

param(
    [string]
    [ValidateNotNullOrEmpty()]
    $ComputerName,

    [string]
    [ValidateNotNullOrEmpty()]
    $AdminPassword,

    [Boolean]
    $DHCP = $false,

    [string]
    $IP,

    [string]
    $Subnet,

    [string]
    $GW,

    [System.Array]
    $DNSServer,

    [Boolean]
    $DomainJoin = $false,

    [string]
    $DomainName ,

    [string]
    $DomainUsername,

    [string]
    $DomainPassword,

    [Boolean]
    $RemoteDesktopEnabled = $True,
    
    [Boolean]
    $DisableIEISC = $True,
    
    [Boolean]
    $AllowFilesinFW = $true,
    
    [Boolean]
    $CopyDSCModules = $false,
    
    [Int64]
    $StartMemory = 2GB,
    
    [Int64]
    $MinMemory = 2GB,
    
    [Int64]
    $MaxMemory = 8GB,

    [string]
    [ValidateNotNullOrEmpty()]
    $SwitchName,

    [int]
    [ValidateNotNullOrEmpty()]
    $Vlan,

    [string]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path $(Resolve-Path $_) })]
    $SysPrepVHDPath,

    [string]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path $(Resolve-Path $_) })]
    $ParentWorkdir,

    [string]
    [ValidateScript( { Test-Path $(Resolve-Path $_) })]
    $DSCModulesPath
)
#endregion#################################



#region Functions
#Create Unattend for VHD 
Function Create-UnattendFileVHD {     
    param (
        [parameter(Mandatory = $true)]
        [string]
        $Computername,
        
        [parameter(Mandatory = $true)]
        [string]
        $AdminPassword,

        [parameter(Mandatory = $true)]
        [string]
        $Path
    )

    if ( Test-Path "$path\Unattend.xml" ) {
        Remove-Item "$Path\Unattend.xml"
    }
    $unattendFile = New-Item "$Path\Unattend.xml" -type File
    $fileContent = @"
<?xml version='1.0' encoding='utf-8'?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

  <settings pass="offlineServicing">
   <component
        xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        language="neutral"
        name="Microsoft-Windows-PartitionManager"
        processorArchitecture="amd64"
        publicKeyToken="31bf3856ad364e35"
        versionScope="nonSxS"
        >
      <SanPolicy>1</SanPolicy>
    </component>
 </settings>
 <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <ComputerName>$Computername</ComputerName>
    </component>
 </settings>
 <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <UserAccounts>
        <AdministratorPassword>
           <Value>$AdminPassword</Value>
           <PlainText>true</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <SkipMachineOOBE>true</SkipMachineOOBE> 
        <SkipUserOOBE>true</SkipUserOOBE> 
      </OOBE>
    </component>
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>0406:00000406</InputLocale>
            <SystemLocale>da-DK</SystemLocale>
            <UserLocale>da-DK</UserLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <RegisteredOwner>PFE</RegisteredOwner>
      <RegisteredOrganization>Contoso</RegisteredOrganization>
    </component>
  </settings>
</unattend>

"@

    Set-Content -path $unattendFile -value $fileContent

    #return the file object
    Return $unattendFile 
}

#endregion
$ErrorActionPreference = "STOP"
$VerbosePreference = "Continue"


#VMFolder
if (!(Test-Path "$ParentWorkdir\$ComputerName\")) {
    mkdir "$ParentWorkdir\$ComputerName\"
}

#TempDir
if (!(test-path("$ParentWorkdir\VMPrepTemp\"))) {
    mkdir "$ParentWorkdir\VMPrepTemp\"
}

$TempDir = "$ParentWorkdir\VMPrepTemp\"
$VHDPath = "$ParentWorkdir\$ComputerName\$ComputerName.vhdx"
$VMPath = "$ParentWorkdir\$ComputerName\"
#Copy VHD
Write-Verbose "Starting Copy"
Copy-Item -Path $SysPrepVHDPath -Destination $VHDPath


Write-Verbose "Starting Unattend"
#Apply Unattend - ComputerName, AdminPassword
$unattendfile = Create-UnattendFileVHD -Computername $ComputerName -AdminPassword $AdminPassword -path $TempDir
New-item -type directory -Path $TempDir\mountdir -force
Write-Verbose "Mounting VHD"
dism /mount-image /imagefile:$VHDPath /index:1 /MountDir:$TempDir\mountdir
Write-Verbose "Apply unattend to VHD"
dism /image:$TempDir\mountdir /Apply-Unattend:$unattendfile
New-item -type directory -Path "$TempDir\mountdir\Windows\Panther" -force
Copy-Item -Path $unattendfile -Destination "$TempDir\mountdir\Windows\Panther\unattend.xml" -force
if ($CopyDSCModules -eq $True) {
    Write-Verbose "Copy DSC to VHD"
    Copy-Item -Path $DSCModulesPath -Destination "$TempDir\mountdir\Program Files\WindowsPowerShell\Modules\" -Recurse -force
}
dism /Unmount-Image /MountDir:$TempDir\mountdir /Commit

Write-Verbose "Create VM"
$VM = New-VM -Name $ComputerName -VHDPath $VHDPath -MemoryStartupBytes $StartMemory -path $VMPath -SwitchName $Switchname -Generation 2 
$VM | Set-VMProcessor -Count 2
$vm | Get-VMIntegrationService | Enable-VMIntegrationService
$VM | Set-VMMemory -DynamicMemoryEnabled $true -MaximumBytes $MaxMemory -MinimumBytes $MinMemory 
if ($vlan -ne 0) {
    $VM | Get-VMNetworkAdapter | Set-VMNetworkAdapterVlan -VlanId $vlan -Access
}

$VM | Start-VM

$password = $AdminPassword | ConvertTo-SecureString -asPlainText -Force
$username = "Administrator"
$VMCreds = New-Object System.Management.Automation.PSCredential($username, $password)


# Wait for PowerShell Direct in the VM to respond
Write-Host "Waiting for PSDirect to $($VM.VMName) for $($VMCreds.UserName)"
$startTime = Get-Date
do {
    $timeElapsed = $(Get-Date) - $startTime
    if ($($timeElapsed).TotalMinutes -ge 10) {
        Write-Host "Could not connect to PS Direct after 10 minutes"
        throw
    } 
    Start-Sleep -sec 5
    $psReady = Invoke-Command -VMId $VM.VMId -Credential $VMCreds `
        -ScriptBlock { $True } -ErrorAction SilentlyContinue
} 
until ($psReady)



$ConfigData = @{ 
    ComputerName         = $ComputerName
    RemoteDesktopEnabled = $RemoteDesktopEnabled
    DisableIEISC         = $DisableIEISC
    AllowFilesinFW       = $AllowFilesinFW
    DHCP                 = $DHCP
    IP                   = $IP
    Subnet               = $Subnet
    GW                   = $GW
    DNSServer            = $DNSServer
    DomainJoin           = $DomainJoin
    DomainName           = $DomainName
    DomainUsername       = $DomainUsername
    DomainPassword       = $DomainPassword
} 

#Initial Configuration
Write-verbose "Invoking Configuration OS Config"
Invoke-Command -VMName $VM.Name -Credential $VMCreds -ArgumentList $ConfigData -ScriptBlock {
    param($ConfigData)

    if ($configdata.DHCP -eq $false) {
        $inf = Get-NetAdapter
        if ((Get-NetIPAddress | ? {$_.IPAddress -eq $ConfigData.IP }) -eq $null ) {
            $inf | New-NetIPAddress -IPAddress $ConfigData.IP -PrefixLength $ConfigData.Subnet -DefaultGateway $ConfigData.GW -AddressFamily IPv4
        }
        $inf | Set-DnsClientServerAddress -ServerAddresses $ConfigData.DNSServer
    }
    if ($configdata.AllowFilesinFW -eq $true) {
        Get-NetFirewallRule | ? {$_.displayname -like "*file*"} | Enable-NetFirewallRule
    }

    if ($ConfigData.RemoteDesktopEnabled -eq $true) {
        set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
        set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1   
    }

    if ($ConfigData.DisableIEISC -eq $true) {
        #MISSING
    }

    if ($ConfigData.DomainJoin -eq $true) {
        start-sleep 20
        $password = $ConfigData.DomainPassword | ConvertTo-SecureString -asPlainText -Force
        $username = $ConfigData.DomainName + "\" + $ConfigData.DomainUsername
        $credential = New-Object System.Management.Automation.PSCredential($username, $password)

        Add-Computer -DomainName $ConfigData.DomainName -Credential $credential
    }

    Enable-PSRemoting
    Restart-Computer -Force
}



Remove-Item -Path $TempDir -Force -Recurse