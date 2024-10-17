#!/usr/bin/env pwsh

# MARKER: NEW PARAM BLOCK

# Dot Source all functions in all ps1 files located in this module
$scriptExecuted = $false

# Try the first path
if (Test-Path "$PSScriptRoot\Private") {
    try {
        Write-Verbose "Trying to execute scripts from: $PSScriptRoot\Private"
        Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" 2>$null | ForEach-Object { 
            . $_.FullName 
        }
        $scriptExecuted = $true
    } catch {
        Write-Verbose "Failed to execute scripts from: $PSScriptRoot\Private"
    }
} else {
    Write-Verbose "Path $PSScriptRoot\Private does not exist."
}

# If the first path fails, try the second path with recursion to handle versioned folders
if (-not $scriptExecuted) {
    if (Test-Path "$HOME/.krew/store/kubetidy") {
        try {
            Write-Verbose "Trying to execute scripts recursively from: $HOME/.krew/store/kubetidy"
            
            # Recursively look for .ps1 files inside the versioned directories
            Get-ChildItem -Path "$HOME/.krew/store/kubetidy\*.ps1" -Recurse 2>$null | ForEach-Object { 
                . $_.FullName 
            }
            $scriptExecuted = $true
        } catch {
            Write-Verbose "Failed to execute scripts from: $HOME/.krew/store/kubetidy"
        }
    } else {
        Write-Verbose "Path $HOME/.krew/store/kubetidy does not exist."
    }
}

# Exit the script if both paths failed
if (-not $scriptExecuted) {
    Write-Error "Failed to execute scripts from both paths. Exiting."
    exit 1
}




# Define the function without parameters (parameters are passed via script-level param())
function Invoke-KubeTidy {

    # START PARAM BLOCK
    [CmdletBinding()]
    param (
        [string]$KubeConfigPath,
        [array]$ExclusionList,
        [bool]$Backup = $true,
        [switch]$Force,
        [switch]$ListClusters,
        [switch]$ListContexts,
        [string]$ExportContexts = "",
        [array]$MergeConfigs,
        [string]$DestinationConfig,
        [switch]$DryRun,
        [Alias("h")] [switch]$Help
    )
    # END PARAM BLOCK

    # Only show help if the Help switch is passed
    # OR if none of the actual action parameters are provided
    if ($Help) {
        Write-Host ""
        Write-Host "Parameters:"
        Write-Host "  -KubeConfigPath      Path to your kubeconfig file."
        Write-Host "  -ExclusionList       Comma-separated list of clusters to exclude from cleanup."
        Write-Host "  -Force               Force cleanup even if no clusters are reachable."
        Write-Host "  -ListClusters        Display a list of all clusters in the kubeconfig file."
        Write-Host "  -ListContexts        Display a list of all contexts in the kubeconfig file."
        Write-Host "  -ExportContexts      Comma-separated list of contexts to export from the kubeconfig."
        Write-Host "  -MergeConfigs        Array of kubeconfig files to merge."
        Write-Host "  -DestinationConfig   Path to save the merged or exported kubeconfig file."
        Write-Host "  -DryRun              Simulate the cleanup process without making changes."
        Write-Host "  -Help                Display this help message."
        return
    }

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
                
    # If ExclusionList is not provided, set it to an empty array
    if (-not $ExclusionList) {
        $ExclusionList = @()
    }
    else {
        # Split ExclusionList into an array if provided as a string
        $ExclusionList = $ExclusionList -split ',' | ForEach-Object { $_.Trim() }
    }
        
    # Check if no parameter was passed
    if (-not $KubeConfigPath) {
        Write-Verbose "No KubeConfigPath provided. Retrieving default path..."
        $KubeConfigPath = Get-KubeConfigPath
    }
        
    # Check if the powershell-yaml module is installed; if not, install it
    if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
        Write-Verbose "powershell-yaml module not found. Installing powershell-yaml..."
        Install-Module -Name powershell-yaml -Force -Scope CurrentUser
    }
        
    try {
        Import-Module powershell-yaml -ErrorAction Stop
        Write-Verbose "powershell-yaml module loaded successfully."
    }
    catch {
        Write-Host "Failed to load powershell-yaml module. Please install it manually." -ForegroundColor Red
        return
    }
    
        
    if ($MergeConfigs) {
        if (-not $DestinationConfig) {
            $DestinationConfig = "$env:USERPROFILE\.kube\config"
        }
        Show-KubeTidyBanner
        Write-Host "Merging kubeconfig files..." -ForegroundColor Yellow
                
        # Call Merge-KubeConfigs with -DryRun only if $DryRun is True
        if ($DryRun) {
            Merge-KubeConfigs -MergeConfigs $MergeConfigs -DestinationConfig $DestinationConfig -DryRun
        }
        else {
            Merge-KubeConfigs -MergeConfigs $MergeConfigs -DestinationConfig $DestinationConfig
        }
        return
    }

    if ($ExportContexts) {
        if (-not $DestinationConfig) {
            $DestinationConfig = "$HOME/.kube/filtered-config"  # Default destination for export
        }
        Show-KubeTidyBanner
        Write-Host "Exporting specified contexts: `n$ExportContexts`n" -ForegroundColor Yellow
        Export-KubeContexts -KubeConfigPath $KubeConfigPath -Contexts $ExportContexts -OutputFile $DestinationConfig
        return
    }
        
    if ($ListClusters) {
        Show-KubeTidyBanner
        Get-AllClusters -KubeConfigPath $KubeConfigPath
        return
    }

    if ($ListContexts) {
        Show-KubeTidyBanner
        Get-KubeContexts -KubeConfigPath $KubeConfigPath
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
    
        # Capture the result of the backup operation using -PassThru
        $backupResult = New-Backup -KubeConfigPath $KubeConfigPath -PassThru

        # If the backup failed, abort the cleanup process
        if (-not $backupResult) {
            Write-Host "Backup failed, aborting cleanup." -ForegroundColor Red
            return
        }
    }
    elseif ($DryRun) {
        Write-Host "Dry run enabled: Skipping backup of the KubeConfig file." -ForegroundColor Yellow
    }

    
    $removedClusters = @()
    $checkedClusters = 0
    $reachableClusters = 0
    $totalClusters = $kubeConfig.clusters.Count
    
    $currentContext = $kubeConfig.'current-context'  # Store the current context for later check
    
    foreach ($cluster in $kubeConfig.clusters) {
        $clusterName = $cluster.name
        $clusterServer = $cluster.cluster.server
        $checkedClusters++
        
        Write-Progress -Activity "Checking Cluster" `
            -Status "Checking $clusterName ($checkedClusters of $totalClusters)" `
            -PercentComplete (($checkedClusters / $totalClusters) * 100)
        
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
    
            # Check if the current-context belongs to a removed cluster
            if ($currentContext) {
                $currentContextCluster = ($kubeConfig.contexts | Where-Object { $_.name -eq $currentContext }).context.cluster
                if ($removedClusters -contains $currentContextCluster) {
                    Write-Verbose "The current context ($currentContext) belongs to a removed cluster. Unsetting current-context."
                    $kubeConfig.'current-context' = $null  # Unset the current context
                }
            }
    
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
    
    # Add the current context if it still exists after cleanup
    $currentContextYaml = ""
    if ($kubeConfig.'current-context') {
        $currentContextYaml = "current-context: $($kubeConfig.'current-context')`n"
    }
    
    $kubeConfigHeader = @"
apiVersion: v1
kind: Config
preferences: {} `n
"@ + $currentContextYaml

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

# MARKER: FUNCTION CALL
