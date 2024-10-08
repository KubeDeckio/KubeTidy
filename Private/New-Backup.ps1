# Function to create a backup of the kubeconfig file
function New-Backup {
    [CmdletBinding()]
    param (
        [string]$KubeConfigPath
    )
    $backupPath = "$KubeConfigPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item -Path $KubeConfigPath -Destination $backupPath
    # If the terminal supports clickable links, this will make the path clickable
    $clickableLink = "`e]8;;file://$backupPath`e\$backupPath`e]8;;`e\" 
    Write-Host "Backup created at $clickableLink" -ForegroundColor Green
    Write-Verbose "Backup of KubeConfig created at path: $backupPath"
}