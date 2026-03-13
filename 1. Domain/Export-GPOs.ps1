
$ExportPath = "C:\Temp\GPOs"

$GPOs = Get-GPO -All

foreach($GPO in $GPOs){
    if(!(Test-Path (Join-Path $ExportPath ($GPO.DisplayName)))){
        mkdir (Join-Path $ExportPath ($GPO.DisplayName))
    }
    $GPO | Backup-GPO -Path (Join-Path $ExportPath ($GPO.DisplayName))
}
