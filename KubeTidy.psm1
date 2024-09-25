<#
.SYNOPSIS
    KubeTidy: A script to clean up your Kubernetes config file by removing unreachable clusters and associated users and contexts.

.DESCRIPTION
    This script removes unreachable clusters from the kubeconfig file and ensures that associated 
    users and contexts that reference the removed clusters are also removed.

.PARAMETER KubeConfigPath
    Path to your kubeconfig file. Defaults to the default Kubernetes location if not specified.

.PARAMETER ExclusionList
    A comma-separated list of cluster names to exclude from cleanup (useful for clusters on VPNs or temporary networks).

.PARAMETER Backup
    Flag to create a backup before cleanup. Defaults to true.

.PARAMETER Force
    Forces cleanup even if no clusters are reachable. Defaults to false.

.PARAMETER Verbose
    Enables verbose logging for detailed output.
#>

[CmdletBinding()]
param (
    [string]$KubeConfigPath = "",
    [string]$ExclusionList = "",
    [bool]$Backup = $true,
    [switch]$Force
)

# Split the ExclusionList by commas to create an array of clusters
$ExclusionArray = $ExclusionList -split ',' | ForEach-Object { $_.Trim() }

# Function to create a backup of the kubeconfig file
function New-Backup {
    [CmdletBinding()]
    param (
        [string]$KubeConfigPath
    )
    $backupPath = "$KubeConfigPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item -Path $KubeConfigPath -Destination $backupPath
    Write-Host "Backup created at $backupPath" -ForegroundColor Green
    Write-Verbose "Backup of KubeConfig created at path: $backupPath"
}

# Function to check if a cluster is reachable using HTTPS request
function Test-ClusterReachability {
    [CmdletBinding()]
    param (
        [string]$ClusterServer
    )
    try {
        Write-Verbose "Testing reachability for cluster server: $ClusterServer"
        $response = Invoke-WebRequest -Uri $ClusterServer -UseBasicParsing -TimeoutSec 5 -SkipCertificateCheck -ErrorAction Stop
        Write-Verbose "Cluster $ClusterServer is reachable."
        return $true
    }
    catch {
        if ($_.Exception.Response) {
            Write-Verbose "Cluster $ClusterServer is reachable but returned an error (e.g., 401 Unauthorized)."
            return $true  # Server is reachable but returned an error like 401
        }
        else {
            Write-Verbose "Cluster $ClusterServer is unreachable due to error: $($_.Exception.Message)"
            return $false
        }
    }
}

# Main Cleanup Function
function Invoke-KubeTidyCleanup {
    [CmdletBinding()]
    param (
        [string]$KubeConfigPath,
        [array]$ExclusionArray,
        [switch]$Force
    )

    # Ensure that the $KubeConfigPath is valid
    if (-not $KubeConfigPath) {
        $homePath = [System.Environment]::GetFolderPath("UserProfile")
        Write-Verbose "No KubeConfig path provided. Using default: $homePath\.kube\config"
        $KubeConfigPath = "$homePath\.kube\config"
    }

    # Check if the powershell-yaml module is installed; if not, install it
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Write-Verbose "powershell-yaml module not found. Installing powershell-yaml..."
        Install-Module -Name powershell-yaml -Force -Scope CurrentUser
    }

    # Import the powershell-yaml module to ensure it's loaded
    Import-Module powershell-yaml -ErrorAction Stop
    Write-Verbose "powershell-yaml module loaded successfully."

    # Display ASCII art and start message
    Write-Host ""
    Write-Host " ██╗  ██╗██╗   ██╗██████╗ ███████╗████████╗██╗██████╗ ██╗   ██╗" -ForegroundColor Cyan
    Write-Host " ██║ ██╔╝██║   ██║██╔══██╗██╔════╝╚══██╔══╝██║██╔══██╗╚██╗ ██╔╝" -ForegroundColor Cyan
    Write-Host " █████╔╝ ██║   ██║██████╔╝█████╗     ██║   ██║██║  ██║ ╚████╔╝ " -ForegroundColor Cyan
    Write-Host " ██╔═██╗ ██║   ██║██╔══██╗██╔══╝     ██║   ██║██║  ██║  ╚██╔╝  " -ForegroundColor Cyan
    Write-Host " ██║  ██╗╚██████╔╝██████╔╝███████╗   ██║   ██║██████╔╝   ██║   " -ForegroundColor Cyan
    Write-Host " ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝╚═════╝    ╚═╝   " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Starting KubeTidy cleanup..." -ForegroundColor Yellow
    Write-Host ""

    # Read kubeconfig file
    Write-Verbose "Reading KubeConfig from $KubeConfigPath"
    $kubeConfigContent = Get-Content -Raw -Path $KubeConfigPath
    $kubeConfig = $kubeConfigContent | ConvertFrom-Yaml

    # Backup original file before cleanup
    if ($Backup) {
        Write-Verbose "Creating a backup of the KubeConfig file."
        New-Backup -KubeConfigPath $KubeConfigPath
    }

    $removedClusters = @()
    $checkedClusters = 0
    $reachableClusters = 0
    $totalClusters = $kubeConfig.clusters.Count

    foreach ($cluster in $kubeConfig.clusters) {
        $clusterName = $cluster.name
        $clusterServer = $cluster.cluster.server
        $checkedClusters++

        Write-Progress -Activity "Checking Cluster:" -Status " $clusterName" -PercentComplete (($checkedClusters / $totalClusters) * 100)

        if ($ExclusionArray -contains $clusterName) {
            Write-Verbose "Skipping cluster $clusterName as it is in the exclusion list."
            continue
        }

        Write-Verbose "Checking reachability for cluster: $clusterName at $clusterServer"
        if (-not (Test-ClusterReachability -ClusterServer $clusterServer)) {
            Write-Verbose "$clusterName is NOT reachable via HTTPS. Marking for removal."
            $removedClusters += $clusterName
        }
        else {
            Write-Verbose "$clusterName is reachable via HTTPS."
            $reachableClusters++
        }
    }

    # Check if all clusters are unreachable
    if ($reachableClusters -eq 0 -and -not $Force) {
        Write-Host "No clusters are reachable. Perhaps the internet is down? Use `-Force` to proceed with cleanup." -ForegroundColor Yellow
        Write-Verbose "No clusters are reachable. Aborting cleanup unless `-Force` is used."
        return
    }

    if ($removedClusters.Count -gt 0) {
        $retainedClusters = $kubeConfig.clusters | Where-Object { $removedClusters -notcontains $_.name }
        $retainedContexts = $kubeConfig.contexts | Where-Object { $removedClusters -notcontains $_.context.cluster }
        $removedUsers = $kubeConfig.contexts | Where-Object { $removedClusters -contains $_.context.cluster } | ForEach-Object { $_.context.user }
        $retainedUsers = $kubeConfig.users | Where-Object { $removedUsers -notcontains $_.name }

        $kubeConfig.clusters = $retainedClusters
        $kubeConfig.contexts = $retainedContexts
        $kubeConfig.users = $retainedUsers

        Write-Host "Removed clusters, users, and contexts related to unreachable clusters." -ForegroundColor Green
        Write-Verbose "Removed the following clusters: $($removedClusters -join ', ')"
    }
    else {
        Write-Host "No clusters were removed." -ForegroundColor Yellow
        Write-Verbose "No clusters were marked for removal."
    }

    # Save updated kubeconfig back to the file
    Write-Verbose "Saving the updated KubeConfig to $KubeConfigPath"
    $kubeConfig | ConvertTo-Yaml | Set-Content -Path $KubeConfigPath
    Write-Host "Kubeconfig cleaned and saved." -ForegroundColor Green

    # Display the summary with consistent padding
    $retainedCount = $kubeConfig.clusters.Count
    $removedCount = $removedClusters.Count
    $checkedClustersText = "{0,5}" -f $checkedClusters
    $removedCountText = "{0,5}" -f $removedCount
    $retainedCountText = "{0,5}" -f $retainedCount

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║               KubeTidy Summary                 ║" -ForegroundColor Magenta
    Write-Host "╠════════════════════════════════════════════════╣" -ForegroundColor Magenta
    Write-Host "║  Clusters Checked: $checkedClustersText                       ║" -ForegroundColor Yellow
    Write-Host "║  Clusters Removed: $removedCountText                       ║" -ForegroundColor Red
    Write-Host "║  Clusters Kept:    $retainedCountText                       ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Magenta
}
