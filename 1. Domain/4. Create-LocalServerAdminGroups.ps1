
$Config = Invoke-Expression -Command (Get-Content -Path 'D:\OneDrive\Git Repos\WSSD Reorgenized\Fabric Domain\ConfigFiles_Gentofte\Fabric_DomainConfig.psd1' -raw)

$Config.DomainConfig.RootDN

$GroupPrefix = "la-"
$GroupPath = "OU=LocalAdminGroups,OU=Groups,OU=FABRIC,$($Config.DomainConfig.RootDN)"
$computers = Get-ADComputer -Filter *

foreach($computer in $computers){
    $adGroup = $null
    $adGroup = Get-ADGroup -Filter "Name -eq 'la-$($computer.Name)'"
    if($adGroup -eq $null){
        $adGroup = New-ADGroup -Name "la-$($computer.Name)" -Path $GroupPath -Description "Local Admin group for server $($computer.Name)" -GroupCategory Security -GroupScope DomainLocal -PassThru
    }  
    else{
        if($adGroup.DistinguishedName.Split(",", 2)[1] -ne $GroupPath){
            Move-ADObject -Identity $adGroup.DistinguishedName -TargetPath $GroupPath 
        }
    }
}