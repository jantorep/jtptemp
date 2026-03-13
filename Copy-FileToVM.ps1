


$VM = get-vm | Out-GridView -PassThru

#ask for parent vhdx for and VMs
[reflection.assembly]::loadwithpartialname("System.Windows.Forms")
$openFile = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    Title = "Please select parent VHDx for SDN VMs (2016 or RS3)." # You can copy it from parentdisks on the Hyper-V hosts somewhere into the lab and then browse for it"
}
#$openFile.Filter = "VHDx files (*.vhdx)|*.vhdx" 
If ($openFile.ShowDialog() -eq "OK") {
    Write-Host  "File $($openfile.FileName) selected" -ForegroundColor Cyan
} 
if (!$openFile.FileName) {
    Write-Host "No VHD was selected... Skipping VM Creation" -ForegroundColor Red
}
$FilePath = $openFile.FileName
$FileName = $openfile.SafeFileName


$VM | Get-VMIntegrationService | Enable-VMIntegrationService
sleep 5
$VM | Copy-VMFile -SourcePath $FilePath -FileSource Host -DestinationPath "C:\Temp\$FileName" -Force -CreateFullPath

