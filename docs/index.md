---
title: Home
layout: home
---

<div style="color: cyan; font-family: monospace; font-size: 18px; line-height: 1.2; white-space: pre; text-align: center;">
██╗  ██╗██╗   ██╗██████╗ ███████╗████████╗██╗██████╗ ██╗   ██╗<br>
██║ ██╔╝██║   ██║██╔══██╗██╔════╝╚══██╔══╝██║██╔══██╗╚██╗ ██╔╝<br>
█████╔╝ ██║   ██║██████╔╝█████╗     ██║   ██║██║  ██║ ╚████╔╝ <br>
██╔═██╗ ██║   ██║██╔══██╗██╔══╝     ██║   ██║██║  ██║  ╚██╔╝  <br>
██║  ██╗╚██████╔╝██████╔╝███████╗   ██║   ██║██████╔╝   ██║   <br>
╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝╚═════╝    ╚═╝   <br>
</div>

Welcome to **KubeTidy**! 

KubeTidy is a PowerShell tool that simplifies managing your Kubernetes `kubeconfig` files. It helps you clean up unreachable clusters, merge configurations, and keep only valid contexts and users. Whether you're a Kubernetes administrator managing multiple clusters or a developer working across environments, KubeTidy can make your life easier by streamlining and organizing your Kubernetes configuration.

## Key Features

- **Cluster Reachability Check**: Remove clusters that are unreachable.
- **User and Context Cleanup**: Clean up users and contexts that are no longer needed.
- **Backup Creation**: Create backups of your original `kubeconfig` before making changes.
- **Merge Kubeconfig Files**: Combine multiple `kubeconfig` files into one.
- **Dry Run Mode**: Simulate cleanup or merging before making actual changes.

Check out our [Installation Guide](docs/installation.md) to get started or [Usage Documentation](docs/usage.md) to explore how you can use KubeTidy.

---

- [Installation](docs/installation.md)
- [Usage](docs/usage.md)
- [GitHub Repository](https://github.com/PixelRobots/KubeTidy)
