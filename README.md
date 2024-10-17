<p align="center">
  <img src="./images/KubeTidy.png" />
</p>
<h1 align="center" style="font-size: 100px;">
  <b>KubeTidy</b>
</h1>

</br>

![Publish Module to PowerShell Gallery](https://github.com/KubeDeckio/KubeTidy/actions/workflows/publish-psgal.yml/badge.svg)
[![Publish Plugin to Krew](https://github.com/KubeDeckio/KubeTidy/actions/workflows/publish-krewplugin.yaml/badge.svg)](https://github.com/KubeDeckio/KubeTidy/actions/workflows/publish-krewplugin.yaml)
![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/KubeTidy.svg)
![Downloads](https://img.shields.io/powershellgallery/dt/KubeTidy.svg)
![Krew Version](https://img.shields.io/github/v/release/KubeDeckio/KubeTidy?label=Krew%20Version)
![License](https://img.shields.io/github/license/KubeDeckio/KubeTidy.svg)

---

**KubeTidy** is a PowerShell tool designed to clean up your Kubernetes configuration file by removing unreachable clusters, along with associated users and contexts. It simplifies the management of your `kubeconfig` by ensuring that only reachable and valid clusters remain, making it easier to work with multiple Kubernetes environments. **KubeTidy** also supports merging multiple `kubeconfig` files into one.

## Documentation

For complete installation, usage, and advanced configuration instructions, please visit the [KubeTidy Documentation Site](https://docs.kubetidy.io).

## Features

- **Cluster Reachability Check:** Automatically remove unreachable clusters.
- **Exclusion List:** Skip specific clusters from removal (e.g., VPN-bound or temporarily unreachable clusters).
- **User and Context Cleanup:** Remove users and contexts associated with removed clusters.
- **Backup Creation:** Create a backup of the original `kubeconfig` before cleanup.
- **Summary Report:** Shows how many clusters were checked, removed, and retained.
- **Force Cleanup Option:** Use the `-Force` parameter to force cleanup even if all clusters are unreachable.
- **List Clusters Option:** List all clusters without performing any cleanup.
- **Merge Kubeconfig Files:** Merge multiple `kubeconfig` files into one.
- **Dry Run Mode:** Simulate cleanup or merging operations without making changes.
- **Verbose Output:** Detailed logging about cluster reachability and other operations.

## Installation

### PowerShell Gallery

To install **KubeTidy** via PowerShell Gallery:

```powershell
Install-Module -Name KubeTidy -Repository PSGallery -Scope CurrentUser
```

### Krew (Linux and macOS)

To install KubeTidy as a kubectl plugin using Krew:

```bash
# Fetch the latest release tag using GitHub's API
LATEST_VERSION=$(curl -s https://api.github.com/repos/KubeDeckio/KubeTidy/releases/latest | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

# Download the KubeTidy.yaml file from the latest release
curl -L -H "Cache-Control: no-cache" -O https://github.com/KubeDeckio/KubeTidy/releases/download/$LATEST_VERSION/KubeTidy.yaml

# Install the plugin using the downloaded KubeTidy.yaml file
kubectl krew install --manifest="./KubeTidy.yaml"
```

### Platform Support

Please note that **KubeTidy** installed via Krew is supported only on Linux and macOS. It does not support Windows at this time.

For additional instructions, refer to the [KubeTidy Documentation Site.](https://docs.kubetidy.io)

## Changelog

All notable changes to this project are documented in the [CHANGELOG](./CHANGELOG.md).

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more details.