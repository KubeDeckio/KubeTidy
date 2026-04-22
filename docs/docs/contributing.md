# Contributing to KubeTidy

Thank you for contributing to **KubeTidy**.

## Getting started

1. Fork the repository.
2. Clone your fork:

```bash
git clone https://github.com/<your-username>/KubeTidy.git
cd KubeTidy
git remote add upstream https://github.com/KubeDeckio/KubeTidy.git
```

## Development environment

Install the main development dependencies:

- Go
- PowerShell 7 if you want to test the wrapper
- Python 3.11+ for docs builds

## Common local commands

```bash
make tidy
make test
make build
python -m pip install -r requirements-docs.txt
mkdocs build --strict
```

## Pull requests

- create a topic branch
- test your changes before opening the PR
- keep docs and release packaging updated when behavior changes

## Standards

- follow existing Go and PowerShell conventions in the repo
- prefer small, reviewable changes
- keep user-facing docs aligned with the real command surface

## Code of conduct

See the [Code of Conduct](https://github.com/KubeDeckio/KubeTidy/blob/main/CODE_OF_CONDUCT.md).
