function Get-KubeContexts {
    param (
        [string]$KubeConfigPath = "$HOME/.kube/config"
    )

    # Check if the config file exists
    if (-not (Test-Path -Path $KubeConfigPath)) {
        Write-Host "Kubeconfig file not found at $KubeConfigPath." -ForegroundColor Red
        return
    }

    # Load the kubeconfig YAML
    $kubeConfigContent = Get-Content -Raw -Path $KubeConfigPath
    $kubeConfig = $kubeConfigContent | ConvertFrom-Yaml

    # List all the contexts
    $contexts = $kubeConfig.contexts
    Write-Host "Listing all contexts in Kubeconfig file: `n" -ForegroundColor Yellow

    $contexts | ForEach-Object {
        Write-Host "Context: $($_.name)" -ForegroundColor Cyan
    }

    # Check if the current-context is set
    if ($kubeConfig.'current-context') {
        Write-Host "`nCurrent context: $($kubeConfig.'current-context')" -ForegroundColor Green
    }
    else {
        Write-Host "`nNo current context is set." -ForegroundColor Red
    }

    # Print the total count of contexts at the end
    $contextCount = $contexts.Count
    Write-Host ""
    Write-Host "Total number of contexts: $contextCount" -ForegroundColor Green
}