<#
.SYNOPSIS
    KubeTidy: A script to clean up your Kubernetes config file by removing unreachable clusters and associated users and contexts, or merge multiple config files.

.DESCRIPTION
    This script removes unreachable clusters from the kubeconfig file and ensures that associated 
    users and contexts that reference the removed clusters are also removed. It can also merge multiple kubeconfig files.

.PARAMETER KubeConfigPath
    Path to your kubeconfig file. Defaults to the default Kubernetes location if not specified.

.PARAMETER ExclusionList
    A comma-separated list of cluster names to exclude from cleanup (useful for clusters on VPNs or temporary networks).

.PARAMETER Backup
    Flag to create a backup before cleanup. Defaults to true.

.PARAMETER Force
    Forces cleanup even if no clusters are reachable. Defaults to false.

.PARAMETER ListClusters
    Displays a list of all clusters in the kubeconfig file without performing cleanup.

.PARAMETER MergeConfigs
    An array of kubeconfig files to merge into the destination kubeconfig file.

.PARAMETER DestinationConfig
    The path to save the merged kubeconfig file. Defaults to the default location if not specified.

.PARAMETER Verbose
    Enables verbose logging for detailed output.
#>

[CmdletBinding()]
param (
    [string]$KubeConfigPath = "",
    [string]$ExclusionList = "",
    [bool]$Backup = $true,
    [switch]$Force,
    [switch]$ListClusters,
    [string[]]$MergeConfigs,
    [string]$DestinationConfig = ""
)

# Split the ExclusionList by commas to create an array of clusters
$ExclusionList = $ExclusionList -split ',' | ForEach-Object { $_.Trim() }

# Function to show KubeTidy Banner
function Show-KubeTidyBanner {
    # Display ASCII art and start message
    Write-Host ""
    Write-Host " ██╗  ██╗██╗   ██╗██████╗ ███████╗████████╗██╗██████╗ ██╗   ██╗" -ForegroundColor Cyan
    Write-Host " ██║ ██╔╝██║   ██║██╔══██╗██╔════╝╚══██╔══╝██║██╔══██╗╚██╗ ██╔╝" -ForegroundColor Cyan
    Write-Host " █████╔╝ ██║   ██║██████╔╝█████╗     ██║   ██║██║  ██║ ╚████╔╝ " -ForegroundColor Cyan
    Write-Host " ██╔═██╗ ██║   ██║██╔══██╗██╔══╝     ██║   ██║██║  ██║  ╚██╔╝  " -ForegroundColor Cyan
    Write-Host " ██║  ██╗╚██████╔╝██████╔╝███████╗   ██║   ██║██████╔╝   ██║   " -ForegroundColor Cyan
    Write-Host " ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝╚═════╝    ╚═╝   " -ForegroundColor Cyan
    Write-Host ""
}

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

# Function to list all clusters in the kubeconfig file
function Get-AllClusters {
    [CmdletBinding()]
    param (
        [string]$KubeConfigPath
    )

    Write-Host "Listing all clusters in KubeConfig file:" -ForegroundColor Yellow
    Write-Host ""
    
    # Read the kubeconfig content
    $kubeConfigContent = Get-Content -Raw -Path $KubeConfigPath
    $kubeConfig = $kubeConfigContent | ConvertFrom-Yaml

    # Get the total number of clusters
    $clusterCount = $kubeConfig.clusters.Count

    # Check if there are clusters in the file
    if ($clusterCount -gt 0) {
        # List the clusters
        foreach ($cluster in $kubeConfig.clusters) {
            $clusterName = $cluster.name
            Write-Host "Cluster: $clusterName" -ForegroundColor Cyan
        }
        
        # Output the total number of clusters
        Write-Host ""
        Write-Host "Total Clusters: $clusterCount" -ForegroundColor Green
    } else {
        Write-Host "No clusters found in the kubeconfig file." -ForegroundColor Red
    }
}


# Function to merge kubeconfig files
# Function to merge kubeconfig files
function Merge-KubeConfigs {
    [CmdletBinding()]
    param (
        [string[]]$MergeConfigs,
        [string]$DestinationConfig
    )

    # Initialize empty hash tables to hold the merged clusters, contexts, and users
    $mergedClusters = @{}
    $mergedContexts = @{}
    $mergedUsers = @{}

    foreach ($configPath in $MergeConfigs) {
        Write-Verbose "Merging config from $configPath"
        $configContent = Get-Content -Raw -Path $configPath
        $config = $configContent | ConvertFrom-Yaml

        # Merge clusters
        foreach ($cluster in $config.clusters) {
            if (-not $mergedClusters.ContainsKey($cluster.name)) {
                $mergedClusters[$cluster.name] = $cluster
            }
        }

        # Merge contexts
        foreach ($context in $config.contexts) {
            if (-not $mergedContexts.ContainsKey($context.name)) {
                $mergedContexts[$context.name] = $context
            }
        }

        # Merge users
        foreach ($user in $config.users) {
            if (-not $mergedUsers.ContainsKey($user.name)) {
                $mergedUsers[$user.name] = $user
            }
        }
    }

    # Create the merged kubeconfig with the correct structure
    $mergedKubeConfig = @"
apiVersion: v1
kind: Config
preferences: {} `n
"@

    # Convert clusters, contexts, and users to YAML
    $clustersYaml = @"
clusters: `n
"@
    foreach ($cluster in $mergedClusters.Values) {
        $clustersYaml += "  - cluster:`n"
        $clustersYaml += "      certificate-authority-data: $($cluster.cluster.'certificate-authority-data')`n"
        $clustersYaml += "      server: $($cluster.cluster.server)`n"
        $clustersYaml += "    name: $($cluster.name)`n"
    }

    $contextsYaml = @"
contexts: `n
"@
    foreach ($context in $mergedContexts.Values) {
        $contextsYaml += "  - context:`n"
        $contextsYaml += "      cluster: $($context.context.cluster)`n"
        $contextsYaml += "      user: $($context.context.user)`n"
        $contextsYaml += "    name: $($context.name)`n"
    }

    $usersYaml = @"
users: `n
"@
    foreach ($user in $mergedUsers.Values) {
        $usersYaml += "  - name: $($user.name)`n"
        $usersYaml += "    user:`n"
        $usersYaml += "      client-certificate-data: $($user.user.'client-certificate-data')`n"
        $usersYaml += "      client-key-data: $($user.user.'client-key-data')`n"
    }

    # Combine everything into one YAML structure
    $fullKubeConfigYaml = $mergedKubeConfig + $clustersYaml + $contextsYaml + $usersYaml

    # Save the merged config to the destination file
    $fullKubeConfigYaml | Set-Content -Path $DestinationConfig
    Write-Host "Merged kubeconfig saved to $DestinationConfig" -ForegroundColor Green

    # Display summary of merged entities
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║            KubeTidy Merge Summary              ║" -ForegroundColor Magenta
    Write-Host "╠════════════════════════════════════════════════╣" -ForegroundColor Magenta
    Write-Host "║  Files Merged:     $($MergeConfigs.Count)                           ║" -ForegroundColor Yellow
    Write-Host "║  Clusters Merged:  $($mergedClusters.Count)                          ║" -ForegroundColor Cyan
    Write-Host "║  Contexts Merged:  $($mergedContexts.Count)                          ║" -ForegroundColor Cyan
    Write-Host "║  Users Merged:     $($mergedUsers.Count)                          ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}


# Main Cleanup or Merge Function
function Invoke-KubeTidy {
    [CmdletBinding()]
    param (
        [string]$KubeConfigPath,
        [array]$ExclusionList,
        [switch]$Force,
        [switch]$ListClusters,
        [string[]]$MergeConfigs,
        [string]$DestinationConfig
    )

    # Ensure that the $KubeConfigPath is valid
    if (-not $KubeConfigPath) {
        # Function to detect if running inside WSL
        function Test-WSL {
            if (Test-Path "/proc/version") {
                $versionInfo = Get-Content "/proc/version"
                return $versionInfo -match "Microsoft"
            }
            return $false
        }

        # Determine the correct kubeconfig path based on the environment
        if ($IsWindows) {
            # Windows: Use the standard USERPROFILE path
            $KubeConfigPath = "$env:USERPROFILE\.kube\config"
        }
        elseif (Test-WSL) {
            # WSL: Use wslvar to get the Windows USERPROFILE and convert it to WSL path using wslpath
            $windowsHomePath = wslpath "$(wslvar USERPROFILE)"
            $KubeConfigPath = "$windowsHomePath/.kube/config"

            if (-not $KubeConfigPath) {
                Write-Error "Could not locate the Windows .kube config path in WSL."
                return
            }
        }
        else {
            # Native Linux/macOS: Use the regular home directory path
            $KubeConfigPath = "$HOME/.kube/config"
        }

        # Output the determined path (for debugging or informational purposes)
        Write-Host "KubeConfig Path: $KubeConfigPath"
    }

    # Check if the powershell-yaml module is installed; if not, install it
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Write-Verbose "powershell-yaml module not found. Installing powershell-yaml..."
        Install-Module -Name powershell-yaml -Force -Scope CurrentUser
    }

    # Import the powershell-yaml module to ensure it's loaded
    Import-Module powershell-yaml -ErrorAction Stop
    Write-Verbose "powershell-yaml module loaded successfully."

    # If MergeConfigs is provided, perform merging
    if ($MergeConfigs) {
        if (-not $DestinationConfig) {
            $DestinationConfig = "$env:USERPROFILE\.kube\config"
        }
        Show-KubeTidyBanner
        Write-Host "Merging kubeconfig files..." -ForegroundColor Yellow
        Merge-KubeConfigs -MergeConfigs $MergeConfigs -DestinationConfig $DestinationConfig
        return
    }

    # If ListClusters flag is provided, list clusters and exit
    if ($ListClusters) {
        Show-KubeTidyBanner
        Get-AllClusters -KubeConfigPath $KubeConfigPath
        return
    }

    # Call the function wherever you need to show the banner
    Show-KubeTidyBanner
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

        if ($ExclusionList -contains $clusterName) {
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

    # Manually build the YAML for clusters, contexts, and users
    $clustersYaml = @"
clusters: `n
"@
    foreach ($cluster in $kubeConfig.clusters) {
        $clustersYaml += "  - cluster:`n"
        $clustersYaml += "      certificate-authority-data: $($cluster.cluster.'certificate-authority-data')`n"
        $clustersYaml += "      server: $($cluster.cluster.server)`n"
        $clustersYaml += "    name: $($cluster.name)`n"
    }

    $contextsYaml = @"
contexts: `n
"@
    foreach ($context in $kubeConfig.contexts) {
        $contextsYaml += "  - context:`n"
        $contextsYaml += "      cluster: $($context.context.cluster)`n"
        $contextsYaml += "      user: $($context.context.user)`n"
        $contextsYaml += "    name: $($context.name)`n"
    }

    $usersYaml = @"
users: `n
"@
    foreach ($user in $kubeConfig.users) {
        $usersYaml += "  - name: $($user.name)`n"
        $usersYaml += "    user:`n"
        $usersYaml += "      client-certificate-data: $($user.user.'client-certificate-data')`n"
        $usersYaml += "      client-key-data: $($user.user.'client-key-data')`n"
    }

    # Manually define the top-level fields
    $kubeConfigHeader = @"
apiVersion: v1
kind: Config
preferences: {} `n
"@

    # Combine everything and save to file
    $fullKubeConfigYaml = $kubeConfigHeader + $clustersYaml + $contextsYaml + $usersYaml
    $fullKubeConfigYaml | Set-Content -Path $KubeConfigPath

    Write-Host "Kubeconfig cleaned and saved." -ForegroundColor Green

    # Display the summary with consistent padding
    $removedCount = $removedClusters.Count
    $checkedClustersText = "{0,5}" -f $checkedClusters
    $removedCountText = "{0,5}" -f $removedCount
    $retainedCountText = "{0,5}" -f ($checkedClusters - $removedCount)

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║               KubeTidy Summary                 ║" -ForegroundColor Magenta
    Write-Host "╠════════════════════════════════════════════════╣" -ForegroundColor Magenta
    Write-Host "║  Clusters Checked:    $checkedClustersText                    ║" -ForegroundColor Yellow
    Write-Host "║  Clusters Removed:    $removedCountText                    ║" -ForegroundColor Red
    Write-Host "║  Clusters Kept:       $retainedCountText                    ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Magenta
}
