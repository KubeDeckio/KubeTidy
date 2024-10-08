---
title: Installation
parent: Documentation
nav_order: 1
layout: default
---

# Installation

KubeTidy can be installed through either the PowerShell Gallery or via Krew for Linux and macOS users.

## Installing via PowerShell Gallery

You can install **KubeTidy** directly from the PowerShell Gallery:

```powershell
Install-Module -Name KubeTidy -Repository PSGallery -Scope CurrentUser
```

To update **KubeTidy**:

```powershell
Update-Module -Name KubeTidy
```

## Installing via Krew (Linux and macOS)

To install KubeTidy as a `kubectl` plugin using [Krew](https://krew.sigs.k8s.io/):

1. **Install Krew**: Follow the instructions [here](https://krew.sigs.k8s.io/docs/user-guide/setup/install/).
2. **Install KubeTidy**: 

```bash
curl -H "Cache-Control: no-cache" -O https://raw.githubusercontent.com/PixelRobots/KubeTidy/main/KubeTidy.yaml
kubectl krew install --manifest="./KubeTidy.yaml"
```

## Requirements

- **PowerShell Version**: PowerShell 7 or higher is required.
- **Additional Dependencies**: The `powershell-yaml` module is needed for YAML parsing. It will be automatically installed when running KubeTidy from PowerShell.

Now that you've installed KubeTidy, head over to the [Usage Guide](/docs/usage) to start cleaning up your Kubernetes configurations!