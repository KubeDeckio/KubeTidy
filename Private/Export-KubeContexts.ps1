function Export-KubeContexts {
    param (
        [string]$KubeConfigPath = "$HOME/.kube/config",
        [string]$OutputFile = "$HOME/.kube/filtered-config",
        [string]$Contexts = ""
    )

    # Check if the config file exists
    if (-not (Test-Path -Path $KubeConfigPath)) {
        Write-Host "Kubeconfig file not found at $KubeConfigPath." -ForegroundColor Red
        return
    }

    # Load the kubeconfig YAML using Powershell-Yaml module
    $kubeConfigContent = Get-Content -Raw -Path $KubeConfigPath
    $kubeConfig = $kubeConfigContent | ConvertFrom-Yaml

    # Split the Contexts parameter into an array of context names
    $contextList = $Contexts -split ',' | ForEach-Object { $_.Trim() }

    if (-not $contextList -or $contextList.Count -eq 0) {
        Write-Host "No contexts specified or invalid context list." -ForegroundColor Red
        return
    }

    # Initialize collections for the filtered items
    $filteredContexts = @()
    $filteredClusters = @()
    $filteredUsers = @()

    # Loop through the context list and gather associated clusters and users
    foreach ($contextName in $contextList) {
        $context = $kubeConfig.contexts | Where-Object { $_.name -eq $contextName }

        if (-not $context) {
            Write-Host "Context $contextName not found in the kubeconfig." -ForegroundColor Yellow
            continue
        }

        # Add the context to the filtered contexts
        $filteredContexts += @{
            name = $context.name
            context = @{
                cluster = $context.context.cluster
                user    = $context.context.user
            }
        }

        # Collect the associated cluster
        $clusterName = $context.context.cluster
        $cluster = $kubeConfig.clusters | Where-Object { $_.name -eq $clusterName }
        if ($cluster -and -not ($filteredClusters | Where-Object { $_.name -eq $clusterName })) {
            $filteredClusters += @{
                name = $cluster.name
                cluster = @{
                    server = $cluster.cluster.server
                    'certificate-authority-data' = $cluster.cluster.'certificate-authority-data'
                }
            }
        }

        # Collect the associated user
        $userName = $context.context.user
        $user = $kubeConfig.users | Where-Object { $_.name -eq $userName }
        if ($user -and -not ($filteredUsers | Where-Object { $_.name -eq $userName })) {
            $filteredUsers += @{
                name = $user.name
                user = @{
                    'client-certificate-data' = $user.user.'client-certificate-data'
                    'client-key-data'         = $user.user.'client-key-data'
                }
            }
        }
    }

    if (-not $filteredContexts) {
        Write-Host "No matching contexts were found." -ForegroundColor Red
        return
    }

    # Create a new kubeconfig structure, ensuring the correct order of preferences after kind
    $newKubeConfig = [ordered]@{
        apiVersion  = "v1"
        kind        = "Config"
        preferences = @{}
        clusters    = $filteredClusters
        contexts    = $filteredContexts
        users       = $filteredUsers
    }

    # Convert the new KubeConfig to YAML using Powershell-Yaml and save it
    $newKubeConfigYaml = ConvertTo-Yaml -Data $newKubeConfig
    Set-Content -Path $OutputFile -Value $newKubeConfigYaml

    Write-Host "`nFiltered kubeconfig exported to $OutputFile." -ForegroundColor Green
}
