function Invoke-KubeTidy {

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

.PARAMETER DryRun
    If specified, the function will simulate the cleanup process without making any changes.

.PARAMETER Verbose
    Enables verbose logging for detailed output.
#>

    [CmdletBinding()]
    param (
        [string]$KubeConfigPath,
        [array]$ExclusionList,
        [switch]$Force,
        [switch]$ListClusters,
        [array]$MergeConfigs,
        [string]$DestinationConfig,
        [switch]$DryRun
    )

    # Split the ExclusionList by commas to create an array of clusters
    $ExclusionList = $ExclusionList -split ',' | ForEach-Object { $_.Trim() }

    # Ensure that the $KubeConfigPath is valid
    if (-not $KubeConfigPath) {
        function Test-WSL {
            if (Test-Path "/proc/version") {
                $versionInfo = Get-Content "/proc/version"
                return $versionInfo -match "Microsoft"
            }
            return $false
        }

        if ($IsWindows) {
            $KubeConfigPath = "$env:USERPROFILE\.kube\config"
        }
        elseif (Test-WSL) {
            $windowsHomePath = wslpath "$(wslvar USERPROFILE)"
            $KubeConfigPath = "$windowsHomePath/.kube/config"

            if (-not $KubeConfigPath) {
                Write-Error "Could not locate the Windows .kube config path in WSL."
                return
            }
        }
        else {
            $KubeConfigPath = "$HOME/.kube/config"
        }

        Write-Host "KubeConfig Path: $KubeConfigPath"
    }

    # Check if the powershell-yaml module is installed; if not, install it
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Write-Verbose "powershell-yaml module not found. Installing powershell-yaml..."
        Install-Module -Name powershell-yaml -Force -Scope CurrentUser
    }

    Import-Module powershell-yaml -ErrorAction Stop
    Write-Verbose "powershell-yaml module loaded successfully."

    if ($MergeConfigs) {
        if (-not $DestinationConfig) {
            $DestinationConfig = "$env:USERPROFILE\.kube\config"
        }
        Show-KubeTidyBanner
        Write-Host "Merging kubeconfig files..." -ForegroundColor Yellow
        
        # Call Merge-KubeConfigs with -DryRun only if $DryRun is True
        if ($DryRun) {
            Merge-KubeConfigs -MergeConfigs $MergeConfigs -DestinationConfig $DestinationConfig -DryRun
        } else {
            Merge-KubeConfigs -MergeConfigs $MergeConfigs -DestinationConfig $DestinationConfig
        }
        return
    }

    if ($ListClusters) {
        Show-KubeTidyBanner
        Get-AllClusters -KubeConfigPath $KubeConfigPath
        return
    }

    Show-KubeTidyBanner
    Write-Host "Starting KubeTidy cleanup..." -ForegroundColor Yellow
    Write-Host ""

    Write-Verbose "Reading KubeConfig from $KubeConfigPath"
    $kubeConfigContent = Get-Content -Raw -Path $KubeConfigPath
    $kubeConfig = $kubeConfigContent | ConvertFrom-Yaml

    # Backup original file before cleanup
    if ($Backup -and -not $DryRun) {
        Write-Verbose "Creating a backup of the KubeConfig file."
        New-Backup -KubeConfigPath $KubeConfigPath
    }
    elseif ($DryRun) {
        Write-Host "Dry run enabled: Skipping backup of the KubeConfig file." -ForegroundColor Yellow
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

    if ($reachableClusters -eq 0 -and -not $Force) {
        Write-Host "No clusters are reachable. Perhaps the internet is down? Use `-Force` to proceed with cleanup." -ForegroundColor Yellow
        Write-Verbose "No clusters are reachable. Aborting cleanup unless `-Force` is used."
        return
    }

    if ($removedClusters.Count -gt 0) {
        if ($DryRun) {
            Write-Host "Dry run enabled: The following clusters would be removed: $($removedClusters -join ', ')" -ForegroundColor Yellow
        }
        else {
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

    $kubeConfigHeader = @"
apiVersion: v1
kind: Config
preferences: {} `n
"@

    if (-not $DryRun) {
        $fullKubeConfigYaml = $kubeConfigHeader + $clustersYaml + $contextsYaml + $usersYaml
        $fullKubeConfigYaml | Set-Content -Path $KubeConfigPath
        Write-Host "Kubeconfig cleaned and saved." -ForegroundColor Green
    }
    else {
        Write-Host "Dry run enabled: Changes to the KubeConfig file were NOT saved." -ForegroundColor Yellow
    }

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