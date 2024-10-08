# Function to merge kubeconfig files
function Merge-KubeConfigs {
    [CmdletBinding()]
    param (
        [string[]]$MergeConfigs,
        [string]$DestinationConfig,
        [switch]$DryRun
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

    # If it's not a dry run, save the merged config to the destination file
    if (-not $DryRun) {
        $fullKubeConfigYaml | Set-Content -Path $DestinationConfig
        Write-Host "Merged kubeconfig saved to $DestinationConfig" -ForegroundColor Green
    }
    else {
        # Dry run: Do not save, but indicate what would have happened
        Write-Host "Dry run enabled: No changes have been made. The merged kubeconfig would have been saved to $DestinationConfig" -ForegroundColor Yellow
    }

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
