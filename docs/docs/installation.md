# Installing KubeTidy

You can install KubeTidy through PowerShell Gallery, Krew, Go, or GitHub release binaries.

## PowerShell Gallery

Install the PowerShell module if you want the `Invoke-KubeTidy` command:

```powershell
Install-Module -Name KubeTidy -Repository PSGallery -Scope CurrentUser
```

Update it with:

```powershell
Update-Module -Name KubeTidy
```

This gives you the `Invoke-KubeTidy` command in PowerShell.

## Krew

Install the `kubectl` plugin:

```bash
kubectl krew install kubetidy
```

Update it with:

```bash
kubectl krew upgrade kubetidy
```

This gives you the `kubectl kubetidy` command.

## Go install

Install the `kubetidy` command directly:

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
