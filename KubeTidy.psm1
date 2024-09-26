# Dot Source all functions in all ps1 files located in this module
Get-ChildItem -Path $PSScriptRoot\public\*.ps1 | ForEach-Object { . $_.FullName }

# Dot Source all functions in all ps1 files located in this module
Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 | ForEach-Object { . $_.FullName }