---
title: PowerShell Usage
parent: Usage
nav_order: 1
layout: default
---

# PowerShell Usage

If you're using **KubeTidy** via PowerShell, here are the usage examples to help you clean up or manage your `kubeconfig` files.

## Clean Up Unreachable Clusters

To remove unreachable clusters from your `kubeconfig`, use the following command:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ExclusionList "cluster1,cluster2"
```

## Merging Kubeconfig Files

To merge multiple `kubeconfig` files into a single file:

```powershell
Invoke-KubeTidy -MergeConfigs "config1.yaml","config2.yaml" -DestinationConfig "$HOME\.kube\config"
```

## Listing Clusters

To list all clusters in your `kubeconfig` without making any changes:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ListClusters
```

## Listing Contexts

To list all contexts in your `kubeconfig`:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ListContexts
```

## Dry Run Mode

Use the `-DryRun` option to simulate the cleanup process without modifying your `kubeconfig`:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ExclusionList "cluster1" -DryRun
```

The Dry Run Mode also works for merging multiple kubeconfig files. This allows you to preview a summary of the merge without making any actual changes to the destination file.

```PowerShell
Invoke-KubeTidy -MergeConfigs "config1.yaml","config2.yaml" -DestinationConfig "$HOME\\.kube\\config" -DryRun
```

For detailed logging examples, check out our [Logging and Output](../logging-output) page.
