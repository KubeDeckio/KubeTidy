<p align="center">
  <img src="./images/KubeTidy.png" />
</p>
<h1 align="center" style="font-size: 100px;">
  <b>KubeTidy</b>
</h1>

![Publish Release](https://github.com/KubeDeckio/KubeTidy/actions/workflows/publish-release.yml/badge.svg)
[![CI](https://github.com/KubeDeckio/KubeTidy/actions/workflows/ci.yaml/badge.svg)](https://github.com/KubeDeckio/KubeTidy/actions/workflows/ci.yaml)
![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/KubeTidy.svg)
![Downloads](https://img.shields.io/powershellgallery/dt/KubeTidy.svg)
![Krew Version](https://img.shields.io/github/v/release/KubeDeckio/KubeTidy?label=Krew%20Version)
![License](https://img.shields.io/github/license/KubeDeckio/KubeTidy.svg)

**KubeTidy** helps you clean up and manage Kubernetes `kubeconfig` files. It removes unreachable clusters, keeps related contexts and users in sync, exports selected contexts, and merges multiple kubeconfig files without stripping supported auth or cluster fields.

## Features

- CLI support for Linux, macOS, and Windows
- PowerShell support via `Invoke-KubeTidy`
- Krew plugin support via `kubectl kubetidy`
- Cleanup of unreachable clusters with backup and dry-run support
- Configurable probe timeout for slow or distant cluster endpoints
- Listing of clusters and contexts
- Kubeconfig report mode for orphaned contexts, unused users, and duplicate servers
- Kubeconfig doctor mode for health checks and actionable warnings
- Structured output in `text`, `json`, or `yaml`
- Export of selected contexts to a filtered kubeconfig
- Merge of multiple kubeconfig files while preserving supported fields and reporting duplicate-name skips
- Multi-file `KUBECONFIG` support with configurable merge strategy
- Shell completion generation for bash, zsh, fish, and PowerShell

## Installation

### PowerShell Gallery

```powershell
Install-Module -Name KubeTidy -Repository PSGallery -Scope CurrentUser
```

### Krew

```bash
kubectl krew install kubetidy
```

### From source

```bash
go install github.com/KubeDeckio/KubeTidy/cmd/kubetidy@latest
```

## Usage

Native CLI:

```bash
kubetidy --kubeconfig "$HOME/.kube/config" --listclusters
kubetidy --kubeconfig "$HOME/.kube/config" --report --output json
kubetidy doctor --kubeconfig "$HOME/.kube/config" --output yaml
kubetidy --kubeconfig "$HOME/.kube/config" --exportcontexts "prod-a,prod-b" --destinationconfig "$HOME/.kube/filtered-config"
kubetidy --mergeconfigs config1.yaml --mergeconfigs config2.yaml --destinationconfig "$HOME/.kube/config" --merge-strategy keep-first
kubetidy completion powershell
```

PowerShell wrapper:

```powershell
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -ListClusters
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -Report -Output json
Invoke-KubeTidy -KubeConfigPath "$HOME\.kube\config" -Doctor -Output yaml
Invoke-KubeTidy -ExportContexts "prod-a,prod-b" -DestinationConfig "$HOME\.kube\filtered-config"
Invoke-KubeTidy -MergeConfigs "config1.yaml","config2.yaml" -DestinationConfig "$HOME\.kube\config"
```

## Documentation

Full documentation is published at [docs.kubetidy.io](https://docs.kubetidy.io).

## Development

```bash
make tidy
make test
make build
```

The roadmap is tracked in [ROADMAP.md](./ROADMAP.md).
