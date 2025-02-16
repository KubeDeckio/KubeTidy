---
title: PowerShell Usage
parent: Usage
nav_order: 1
layout: default
---

# PowerShell Usage

If you're using **KubeTidy** via PowerShell, this guide will help you clean up, manage, and optimize your `kubeconfig` files. Below are detailed instructions and examples for various commands.

## Available Commands

The following table provides a quick reference for KubeTidy commands:

| Action                    | Command Example |
|---------------------------|----------------|
| Remove unreachable clusters | `Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ExclusionList "cluster1,cluster2"` |
| Merge kubeconfig files | `Invoke-KubeTidy -MergeConfigs "config1.yaml","config2.yaml" -DestinationConfig "$HOME\.kube\config"` |
| List clusters | `Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ListClusters` |
| List contexts | `Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ListContexts` |
| Export specific contexts | `Invoke-KubeTidy -ExportContexts "context1,context2" -DestinationConfig "$HOME\.kube\filtered-config"` |
| Run in dry-run mode | `Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -DryRun` |
| Enable verbose logging | `Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -Verbose` |

## 1. Backup and Restore

KubeTidy automatically creates a backup before modifying your kubeconfig file unless `-DryRun` is enabled. If you need to restore the original kubeconfig, locate the backup file:

```powershell
$HOME\.kube\config.backup
```

You can also create a manual backup before running KubeTidy:

```powershell
Copy-Item -Path "$HOME\.kube\config" -Destination "$HOME\.kube\config.backup"
```

## 2. Cleaning Up Unreachable Clusters

If your `kubeconfig` contains outdated or unreachable clusters, KubeTidy can remove them automatically. The following command will clean up all unreachable clusters while keeping those listed in `-ExclusionList`:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ExclusionList "cluster1,cluster2"
```

By default, KubeTidy will create a backup of your `kubeconfig` before making changes. If you only want to preview the changes, use the `-DryRun` option.

## 3. Handling Current Context

If the cluster associated with your `current-context` is removed during cleanup, KubeTidy will unset it. If this happens, set a new context manually:

```powershell
kubectl config use-context <new-context>
```

To check your current context before running KubeTidy:

```powershell
kubectl config current-context
```

## 4. Merging Multiple Kubeconfig Files

If you manage multiple Kubernetes environments, you may need to merge several kubeconfig files into one. Use the following command to combine them:

```powershell
Invoke-KubeTidy -MergeConfigs "config1.yaml","config2.yaml" -DestinationConfig "$HOME\.kube\config"
```

To preview the merge process without making changes:

```powershell
Invoke-KubeTidy -MergeConfigs "config1.yaml","config2.yaml" -DestinationConfig "$HOME\.kube\config" -DryRun
```

## 5. Exporting Specific Contexts

You might need to extract specific contexts from a large kubeconfig file to create a smaller, focused configuration. The following command exports only the specified contexts:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ExportContexts "context1,context2" -DestinationConfig "$HOME\.kube\filtered-config"
```

This is useful when sharing configuration files without exposing unnecessary clusters.

## 6. Using Dry Run Mode

Use the `-DryRun` option to simulate the cleanup process without making changes. This helps you understand what will be removed before running the actual cleanup:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ExclusionList "cluster1" -DryRun
```

Dry Run Mode also applies to merging kubeconfig files. Run the following command to preview a merge:

```powershell
Invoke-KubeTidy -MergeConfigs "config1.yaml","config2.yaml" -DestinationConfig "$HOME\.kube\config" -DryRun
```

## 7. Listing Clusters

To display all clusters in your kubeconfig without modifying it:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ListClusters
```

## 8. Listing Contexts

To see all available contexts in your kubeconfig:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ListContexts
```

## 9. Enabling Verbose Logging

For detailed logging, use the `-Verbose` flag:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -Verbose
```

This provides additional details on each step, such as cluster reachability checks and file modifications.

For more information on logging and output, refer to the [Logging and Output](../logging-output) page.

