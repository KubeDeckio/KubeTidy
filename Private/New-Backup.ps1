function New-Backup {
    [CmdletBinding()]
    param (
        [string]$KubeConfigPath,
        [switch]$PassThru  # Add PassThru parameter to return success/failure
    )
    
    $backupPath = "$KubeConfigPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

    try {
        # Attempt to create the backup
        Copy-Item -Path $KubeConfigPath -Destination $backupPath -ErrorAction Stop
        
        # If the terminal supports clickable links, this will make the path clickable
        $clickableLink = "`e]8;;file://$backupPath`e\$backupPath`e]8;;`e\" 
        Write-Host "Backup created at $clickableLink `n" -ForegroundColor Green
        Write-Verbose "Backup of KubeConfig created at path: $backupPath"

        # Return True if PassThru is specified
        if ($PassThru) {
            return $true
        }
    }
    catch {
        # Handle any errors that occurred during the copy operation
        Write-Host "Failed to create a backup of the KubeConfig file." -ForegroundColor Red
        Write-Verbose "Error: $_"

        # Return False if PassThru is specified
        if ($PassThru) {
            return $false
        }
    }
}
