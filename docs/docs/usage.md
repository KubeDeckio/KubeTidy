---
title: Usage
parent: Documentation
nav_order: 3
layout: default
---

# Usage

Once installed, you can start using **KubeTidy** to clean up your `kubeconfig` or manage multiple configurations.

## Basic Usage

### PowerShell Gallery Example

To clean your Kubernetes configuration and remove unreachable clusters:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ExclusionList "cluster1,cluster2"
```

### Krew Plugin Example (Linux/macOS)

Run KubeTidy as a `kubectl` plugin:

```bash
kubectl kubetidy -kubeconfig "$HOME/.kube/config" -exclusionlist "cluster1,cluster2"
```

### Merging Multiple Kubeconfig Files

To merge multiple `kubeconfig` files into one:

```powershell
Invoke-KubeTidy -MergeConfigs "config1.yaml","config2.yaml" -DestinationConfig "$HOME\.kube\config"
```

This will combine `config1.yaml` and `config2.yaml` into the destination file.

## Advanced Options

- **`-ListClusters`**: Lists all clusters in your `kubeconfig` without performing any cleanup.

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ListClusters
```

- **`-ListContexts`**: Lists all contexts in your `kubeconfig` without making changes.

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ListContexts
```

- **`-DryRun`**: Simulates the cleanup process without making any actual changes.

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ExclusionList "cluster1" -DryRun
```

This will show the summary of what would be removed, but won't modify the file.

## Verbose Logging

Use the `-Verbose` flag for detailed logging about the cleanup process, including cluster reachability and which clusters or contexts were removed:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -Verbose
```

For more examples and details, refer to our [GitHub documentation](https://github.com/PixelRobots/KubeTidy).