---
title: Home
nav_order: 1
layout: home
---

<p align="center">
<img id="logo" src="assets/images/KubeTidyDark.png" />
</p>

Welcome to **KubeTidy**! 

KubeTidy is a PowerShell tool that simplifies managing your Kubernetes `kubeconfig` files. It helps you clean up unreachable clusters, merge configurations, and keep only valid contexts and users. Whether you're a Kubernetes administrator managing multiple clusters or a developer working across environments, KubeTidy can make your life easier by streamlining and organizing your Kubernetes configuration.

## Key Features

- **Cluster Reachability Check**: Automatically removes unreachable clusters and their associated users and contexts.
- **Exclusion List**: Keep specific clusters even if they are temporarily unreachable.
- **Merge Kubeconfig Files**: Combine multiple `kubeconfig` files into one.
- **Backup & Summary**: Automatically back up your original `kubeconfig` and get a summary of the changes made.
- **Force Cleanup**: Remove all clusters, even if unreachable, with the `-Force` parameter.
- **List & Export Options**: List or export clusters and contexts without making changes.
- **Dry Run Mode**: Simulate cleanup or merging operations to preview the results.
- **Verbose Logging**: Get detailed logs for all operations using the `-Verbose` flag.


Check out our [Installation Guide](docs/installation) to get started or [Usage Documentation](docs/usage) to explore how you can use KubeTidy.

---

- [Installation](docs/installation)
- [Usage](docs/usage)
- [GitHub Repository](https://github.com/PixelRobots/KubeTidy)
