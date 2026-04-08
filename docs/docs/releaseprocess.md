# KubeTidy Release Process

KubeTidy releases are built from Git tags such as `v0.0.21` or `v0.0.21-rc1`.

## What a tagged release does

- runs Go tests
- builds native binaries for Linux, macOS, and Windows
- publishes Krew archives and updates `KubeTidy.yaml`
- publishes the PowerShell module with the wrapper and bundled binaries
- rebuilds the MkDocs site for GitHub Pages
- marks rc-style tags as GitHub prereleases

## Release steps

1. Create a stable or release-candidate tag locally:

```bash
git tag v0.0.21
git tag v0.0.21-rc1
```

2. Push the tag:

```bash
git push origin v0.0.21
```

3. GitHub Actions handles the rest through:

- `.github/workflows/ci.yaml`
- `.github/workflows/publish-release.yml`
- `.github/workflows/pages.yml`

## Local verification before tagging

```bash
make tidy
make test
make build
python -m pip install -r requirements-docs.txt
mkdocs build --strict
```
