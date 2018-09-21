
Get-ChildItem -Path "$PSScriptRoot\Qualys" | Where-Object {$_.Name.EndsWith(".ps1")} | ForEach-Object {. $_.FullName}
