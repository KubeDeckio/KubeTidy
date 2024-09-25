<p align="center">
  <img src="./images/KubeTidy.png" />
</p>
<h1 align="center" style="font-size: 100px;">
  <b>KubeTidy</b>
</h1>

</br>

**KubeTidy** is a PowerShell tool designed to clean up your Kubernetes configuration file by removing unreachable clusters, along with associated users and contexts. It simplifies the management of your `kubeconfig` by ensuring that only reachable and valid clusters remain, making it easier to work with multiple Kubernetes environments.

## Features

- **Cluster Reachability Check:** Checks clusters to ensure they are reachable and removes those that are not.
- **Exclusion List:** Allows you to specify clusters to skip from removal (useful for VPN-bound or temporarily unreachable clusters).
- **User and Context Cleanup:** Automatically removes users and contexts associated with removed clusters.
- **Backup Creation:** Automatically creates a backup of the original kubeconfig before performing any cleanup.
- **Summary Report:** Provides a neat summary of how many clusters were checked, removed, and retained.
- **Force Cleanup Option:** If all clusters are unreachable, KubeTidy can force a cleanup using the `-Force` parameter.

## Requirements

- PowerShell 5.1 or higher.
- [powershell-yaml](https://www.powershellgallery.com/packages/powershell-yaml) module for YAML parsing.

## Installation

You can install **KubeTidy** directly from the PowerShell Gallery:

```powershell
Install-Module -Name KubeTidy -Repository PSGallery -Scope CurrentUser
```

To update the module later:

```powershell
Update-Module -Name KubeTidy
```
Ensure you have the required dependencies installed by running the tool. It will automatically install the `powershell-yaml` module if not already installed.

## Usage

Once installed, run **KubeTidy** to clean your kubeconfig:

```powershell
Invoke-KubeTidyCleanup -KubeConfigPath "$HOME\.kube\config" -ExclusionList "cluster1,cluster2,cluster3"
```

### Parameters

- **`-KubeConfigPath`**: Path to your `kubeconfig` file. Defaults to `"$HOME\.kube\config"` if not specified.
- **`-ExclusionList`**: A comma-separated list of clusters to exclude from removal. (Useful for clusters requiring VPN or temporary networks.)
- **`-Backup`**: Set to `false` if you don't want a backup to be created. Defaults to `true`.
- **`-Force`**: Forces cleanup even if no clusters are reachable. Use this when you want to proceed with cleanup despite network issues.

### Example

To exclude specific clusters from removal and clean up your kubeconfig:

```powershell
Invoke-KubeTidyCleanup -KubeConfigPath "$HOME\.kube\config" -ExclusionList "aks-prod-cluster,aks-staging-cluster"
```

If no clusters are reachable and you still want to proceed:

```powershell
Invoke-KubeTidyCleanup -KubeConfigPath "$HOME\.kube\config" -ExclusionList "aks-prod-cluster,aks-staging-cluster" -Force
```

## Output

After execution, you will receive a summary like the following:

```
╔════════════════════════════════════════════════╗
║               KubeTidy Summary                 ║
╠════════════════════════════════════════════════╣
║  Clusters Checked:    26                       ║
║  Clusters Removed:     2                       ║
║  Clusters Kept:       24                       ║
╚════════════════════════════════════════════════╝
```

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more details.
