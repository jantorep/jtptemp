

# NewRDSSetup.ps1
# Build 1.0
# Steven Wood - CTGlobal
# Prereqs: Skal køres fra C:\install på gateway
#          Manuelt tilføj alle serveres til "All SErvers" i ServerManager
#          DNS til externalfqdn og externalbrokerfqdn skal være oprettet
#          PFX og Password kopieres til c:\install
#          Download Set-RDPublishedname fra https://gallery.technet.microsoft.com/Change-published-FQDN-for-2a029b80 kopier til c:\install
# 


 
#Evt modificer de servernavne som skal være en del af mijøet 
$rdsbrokername          = "faRDS-P01.fabric.gentofte.dk"   #Servername fqdn
$rdswebsrvname          = "faRDS-P01.fabric.gentofte.dk"   #Servername fqdn
$rdshosts               = "faRDS-P01.fabric.gentofte.dk"   #Servername fqdn
$rdsgateway             = "faRDS-P01.fabric.gentofte.dk"   #Servername fqdn
$rdslicensesrvname      = "faRDS-P01.fabric.gentofte.dk"   #Servername fqdn

$externalfqdn           = "rds01.fabric.gentofte.dk"         #URL brugerne skal besøge: OBS - skal kunne resolves inden nedenstående.
$externalbrokerfqdn     = "rds01.fabric.gentofte.dk"         #Hvis GW og Broker splittet op, skal der laves en URL til broker - og gw skal kunne resolve.
$rdsCollectionname      = "FabricMgmt"             #Titlen på Workspace og ikonet der publiseres.
$rdscertificatepath     = "\\famgmtworker\d`$\Sources\Scripts\rds\RDSCertV2.pfx"
$rdscertificatepassword = Read-Host -Prompt "Enter cert password" -AsSecureString

$RDSUserGroup = "UR-FabricAdmin"


#Installer windows roller:
Add-WindowsFeature –Name RDS-Web-Access –IncludeAllSubFeature -ComputerName $rdswebsrvname
Add-WindowsFeature –Name RDS-Gateway –IncludeAllSubFeature -ComputerName $rdsgateway
Add-WindowsFeature –Name RDS-RD-Server –IncludeAllSubFeature -ComputerName $rdshosts
Add-WindowsFeature –Name RDS-Connection-Broker  –IncludeAllSubFeature -ComputerName $rdsbrokername -Restart


#Import-Module
Import-module RemoteDesktop
Import-module RemoteDesktopServices
Import-module ServerManager

#region Add server to Server Manager
get-process ServerManager | stop-process –force
$file = get-item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\ServerManager\ServerList.xml"
copy-item –path $file –destination $file-backup –force
$xml = [xml] (get-content $file )
$newserver = @($xml.ServerList.ServerInfo)[0].clone()

$newserver.name = $rdshosts
$newserver.lastUpdateTime = “0001-01-01T00:00:00”
$newserver.status = “2”
$xml.ServerList.AppendChild($newserver)


$xml.Save($file.FullName)
Start-Process –filepath $env:SystemRoot\System32\ServerManager.exe –WindowStyle Maximized
#endregion Add server to Server Manager


New-RDSessionDeployment -ConnectionBroker $rdsbrokername -WebAccessServer $rdswebsrvname -SessionHost $rdshosts
Add-RDServer -Server $rdsgateway -Role RDS-GATEWAY -ConnectionBroker $rdsbrokername -GatewayExternalFqdn $externalfqdn 
Add-RDServer -Server $rdslicensesrvname -Role RDS-LICENSING -ConnectionBroker $rdsbrokername
Set-RDLicenseConfiguration -LicenseServer $rdslicensesrvname -Mode PerUser -ConnectionBroker $rdsbrokername

#Always use gateway
Set-RDDeploymentGatewayConfiguration -GatewayMode Custom -BypassLocal $false -ConnectionBroker $rdsbrokername -Force

#certifikater
$pfxpassword = $rdscertificatepassword
Set-RDCertificate -Role RDGateway -ImportPath $rdscertificatepath -Password $pfxpassword -ConnectionBroker $rdsbrokername -Force
Set-RDCertificate -Role RDWebAccess -ImportPath $rdscertificatepath -Password $pfxpassword -ConnectionBroker $rdsbrokername -Force
Set-RDCertificate -Role RDRedirector -ImportPath $rdscertificatepath -Password $pfxpassword -ConnectionBroker $rdsbrokername -Force
Set-RDCertificate -Role RDPublishing -ImportPath $rdscertificatepath -Password $pfxpassword -ConnectionBroker $rdsbrokername -Force
Get-RDCertificate -ConnectionBroker $rdsbrokername

New-RDSessionCollection -CollectionName $rdsCollectionname -SessionHost $rdshosts -ConnectionBroker $rdsbrokername 
Set-RDSessionCollectionConfiguration -CollectionName $rdsCollectionname -CustomRdpProperty "use redirection server name:i:1`r`n use multimon:i:0`r`n smart sizing:i:1`r`n" -ConnectionBroker $rdsbrokername
Set-RDSessionCollectionConfiguration -CollectionName $rdsCollectionname -DisableUserProfileDisk -ConnectionBroker $rdsbrokername
Set-RDSessionCollectionConfiguration -CollectionName $rdsCollectionname -ClientDeviceRedirectionOptions "Clipboard" -ConnectionBroker $rdsbrokername
Set-RDSessionCollectionConfiguration -CollectionName $rdsCollectionname -ClientPrinterAsDefault $false -ClientPrinterRedirected $false -RDEasyPrintDriverEnabled $false -ConnectionBroker $rdsbrokername
Set-RDWorkspace -Name $rdsCollectionname -connectionbroker $rdsbrokername
Set-RDSessionCollectionConfiguration -CollectionName $rdsCollectionname -UserGroup $RDSUserGroup -connectionbroker $rdsbrokername


#Redirect til /RDWeb
Invoke-Command -ComputerName $rdswebsrvname -ScriptBlock {
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site/RDWeb/Pages'  -filter "appSettings/add[@key='PasswordChangeEnabled']" -name "value" -value "true"
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site/RDWeb/Pages'  -filter "appSettings/add[@key='ShowDesktops']" -name "value" -value "false"
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site/RDWeb/Pages'  -filter "appSettings/add[@key='ShowOptimizeExperience']" -name "value" -value "true"
    Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site/RDWeb/Pages'  -filter "appSettings/add[@key='DefaultTSGateway']" -name "value" -value "$rdsgateway"
    New-Item RDS:\GatewayServer\GatewayManagedComputerGroups\RDG_RDCBComputers\Computers -Name $externalbrokerfqdn -ItemType "string"
}



#If broker is installed on GW - use same URL - if broker and GW are split - use a broker url and make sure it can be resolved by GW.

#Hvis Brokeren kører i HA setup - bruges Set-RDClientAccessName og lav round robin DNS til det navn
& '\\famgmtworker\d$\Sources\Scripts\rds\Set-RDPublishedname.ps1' $externalbrokerfqdn -ConnectionBroker $rdsbrokername

#Tillad adgang til broker URL'en i NPS serveren:
#OBS Den URL der bruges skal kunne navneopløses – MANGLER NOGET DER  KAN CHECKE!!!
Import-Module RemoteDesktopServices
Get-ChildItem RDS:\GatewayServer\GatewayManagedComputerGroups\RDG_RDCBComputers\Computers
New-Item RDS:\GatewayServer\GatewayManagedComputerGroups\RDG_RDCBComputers\Computers -Name $externalbrokerfqdn -ItemType "string"


#Install RD Web Client HTML5
Enter-PSSession -ComputerName $rdswebsrvname
Install-Module -Name PowerShellGet -Force
Install-Module -Name RDWebClientManagement
Install-RDWebClientPackage
Import-RDWebClientBrokerCert -Path C:\temp\RDSCertV2.cer
Publish-RDWebClientPackage -Type Production -Latest
Set-WebConfiguration system.webServer/httpRedirect "IIS:\sites\Default Web Site" -Value @{enabled="true";destination="/RDWeb/webclient/";exactDestination="true";httpResponseStatus="Found"} 


Get-WindowsFeature *rsat* | Install-WindowsFeature -ComputerName $rdshosts
#RemoteApps
New-RDRemoteApp -DisplayName "Remote Desktop" -FilePath "C:\Windows\System32\mstsc.exe" -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname
New-RDRemoteApp -DisplayName "Active Directory Users and Computers" -FilePath "C:\Windows\system32\dsa.msc" -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname -IconPath "C:\Windows\system32\dsadmin.dll"
New-RDRemoteApp -DisplayName "DHCP" -FilePath "C:\Windows\system32\dhcpmgmt.msc" -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname -IconPath "C:\Windows\system32\dhcpsnap.dll"
New-RDRemoteApp -DisplayName "Group Policy Management" -FilePath "C:\Windows\system32\gpmc.msc" -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname -IconPath "C:\Windows\System32\gpoadmin.dll"
New-RDRemoteApp -DisplayName "DNS" -FilePath "C:\Windows\system32\dnsmgmt.msc" -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname -IconPath "C:\Windows\system32\dnsmgr.dll"
New-RDRemoteApp -DisplayName "Windows Server Update Services" -FilePath "$env:ProgramFiles\Update Services\AdministrationSnapin\wsus.msc" -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname -IconPath "$env:ProgramFiles\Update Services\AdministrationSnapin\wsus.ico"
#New-RDRemoteApp -DisplayName "Failover Cluster Manager" -FilePath "C:\Windows\system32\CluAdmin.msc" -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname
#New-RDRemoteApp -DisplayName "Hyper-V Manager" -FilePath "C:\Windows\system32\virtmgmt.msc" -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname



#Install Apps for RDS Server
Enter-PSSession -ComputerName $rdshosts -Authentication Credssp -Credential (Get-Credential)

#region Install VMM Console
$VMMSetup = "\\famgmtworker\D$\Sources\SC1801\System Center Virtual Machine Manager\setup.exe"

$unattendFile = New-Item "c:\temp\vmClient.ini" -type File
$fileContent = @"
[OPTIONS]
ProgramFiles=C:\Program Files\Microsoft System Center\Virtual Machine Manager
IndigoTcpPort=8100
MUOptIn = 0
"@
Set-Content $unattendFile $fileContent

& $VMMSetup /client /i /f c:\temp\vmClient.ini /IACCEPTSCEULA

New-RDRemoteApp -DisplayName "Virtual Machine Manager Console" -FilePath "C:\Program Files\Microsoft System Center\Virtual Machine Manager\bin\VmmAdminUI.exe" -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname
#endregion Install VMM Console

#region Install SCOM Console
$SQLSYSCLRTypesPath = "\\famgmtworker\D$\Sources\SC1801\SCOM2016_1801Prereqs\SQLSysClrTypes.msi"
$ReportViewerPath = "\\famgmtworker\D$\Sources\SC1801\SCOM2016_1801Prereqs\ReportViewer.msi"
$SCOMSetup = "\\famgmtworker\D$\Sources\SC1801\System Center Operations Manager\Setup.exe"


cmd.exe /c "msiexec /i $SQLSYSCLRTypesPath /q"

cmd.exe /c "msiexec /i $ReportViewerPath /q"

& $SCOMSetup /silent /install /components:OMConsole /EnableErrorReporting:Never /SendCEIPReports:0 /UseMicrosoftUpdate:0 /AcceptEndUserLicenseAgreement:1
New-RDRemoteApp -DisplayName "Operations Console" -FilePath "C:\Program Files\Microsoft System Center\Operations Manager\Console\Microsoft.EnterpriseManagement.Monitoring.Console.exe" -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname

#endregion Install SCOM Console

#region Install Chrome
Invoke-WebRequest "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile c:\temp\chrome_installer.exe
Unblock-File -Path c:\temp\chrome_installer.exe
Start-Process -FilePath "c:\temp\chrome_installer.exe" -Args "/silent /install" -Verb RunAs -Wait

New-RDRemoteApp -DisplayName "Google Chrome" -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname
New-RDRemoteApp -DisplayName "Windows Admin Center" -FilePath "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" -RequiredCommandLine "https://wac.fabric.gentofte.dk:9999" -IconPath "\\faMGMTworker\d$\Sources\favicon.ico" -CommandLineSetting Require -ConnectionBroker $rdsbrokername -CollectionName $rdsCollectionname

New-Item -Path HKLM:\Software\Policies -Name Google –Force
New-Item -Path HKLM:\Software\Policies\Google -Name Chrome –Force
New-ItemProperty -Path HKLM:Software\Policies\Google\Chrome\ -Name AuthNegotiateDelegateWhitelist -Value "*.$((Get-WmiObject win32_computersystem).Domain)"
#endregion Install VMM Console

Write-Host "Activate RDS licensing manually" -ForegroundColor Yellow
Write-Host "Activate RDS licensing manually" -ForegroundColor Yellow
Write-Host "Activate RDS licensing manually" -ForegroundColor Yellow
Write-Host "Activate RDS licensing manually" -ForegroundColor Yellow