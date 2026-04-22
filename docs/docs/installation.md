# Installing KubeTidy

Choose the installation method that best fits how you want to run **KubeTidy**: from PowerShell, through `kubectl`, directly as a CLI, or from a release binary.

## PowerShell Gallery

Install the PowerShell module if you want to use **KubeTidy** with the `Invoke-KubeTidy` command:

```powershell
Install-Module -Name KubeTidy -Repository PSGallery -Scope CurrentUser
```

Update it with:

```powershell
Update-Module -Name KubeTidy
```

This is the best option if you mainly work in PowerShell or want to use KubeTidy in existing PowerShell scripts.

## Krew

Install the `kubectl` plugin if you want to run **KubeTidy** as part of your Kubernetes command workflow:

```bash
kubectl krew install kubetidy
```

Update it with:

```bash
kubectl krew upgrade kubetidy
```

This is a good fit if you prefer to keep kubeconfig tooling alongside your existing `kubectl` workflow.

## Go install

Install the `kubetidy` command directly if you want the standalone CLI:

```bash
go install github.com/KubeDeckio/KubeTidy/cmd/kubetidy@latest
```

## GitHub releases

Release assets include platform-specific binaries for:

- Linux amd64
- Linux arm64
- macOS amd64
- macOS arm64
- Windows amd64

## Release candidates

Pre-release tags such as `v0.0.21-rc1` are supported in the GitHub release workflows. Release candidate builds are published as prereleases and keep the rc label in versioned assets.
