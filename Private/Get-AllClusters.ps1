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