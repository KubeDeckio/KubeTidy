---
title: Logging and Output
parent: Usage
nav_order: 3
layout: default
---

# Logging and Output

KubeTidy provides detailed output and logging for each operation. You can use the `-Verbose` flag to see detailed information about cluster reachability, user and context removal, and more.

## Verbose Logging Example

Use the `-Verbose` flag for detailed logging during the cleanup process:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -Verbose
```

### Verbose Output Example

```
VERBOSE: Checking reachability for cluster: aks-prod-cluster at https://example-cluster-url
VERBOSE: Cluster aks-prod-cluster is reachable via HTTPS.
VERBOSE: Removing unreachable cluster: aks-old-cluster
VERBOSE: Removed associated user: aks-old-user
VERBOSE: Backup of kubeconfig created: C:\Users\username\.kube\config.backup
```

## Summary Output

After running KubeTidy, a summary is displayed showing how many clusters were checked, removed, or retained:

```
╔════════════════════════════════════════════════╗
║               KubeTidy Summary                 ║
╠════════════════════════════════════════════════╣
║  Clusters Checked:    26                       ║
║  Clusters Removed:     2                       ║
║  Clusters Kept:       24                       ║
╚════════════════════════════════════════════════╝
```

![KubeTidy Cleanup Summary](../../../assets/images/summary.png)
