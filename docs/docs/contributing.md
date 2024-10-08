---
title: Contributing
parent: Documentation
nav_order: 3
layout: default
---
# Contributing to KubeTidy

🎉 Thank you for considering contributing to **KubeTidy**! 🎉

We welcome contributions of all kinds, whether it’s reporting bugs, suggesting improvements, or contributing code. This guide will help you understand how to contribute effectively.

## Getting Started

### Fork & Clone the Repository

1. **Fork** the repository by clicking the "Fork" button at the top-right of this page.
2. **Clone** the forked repository to your local machine:

   ```bash
   git clone https://github.com/<your-username>/KubeTidy.git
   cd KubeTidy
   ```

3. Add the main **KubeTidy** repository as a remote:

   ```bash
   git remote add upstream https://github.com/PixelRobots/KubeTidy.git
   ```

### Set Up Your Development Environment

Before contributing, ensure that you have the required dependencies installed:

- PowerShell 7 or higher.
- Install the [powershell-yaml](https://www.powershellgallery.com/packages/powershell-yaml) module:

   ```bash
   Install-Module -Name powershell-yaml -Scope CurrentUser
   ```

### Create a Branch

Always create a new branch for your work to keep the `main` branch clean. Use descriptive branch names:

```bash
git checkout -b feature/my-new-feature
```

## How to Contribute

### Reporting Bugs

If you find a bug, please **open an issue** on GitHub. Include as much detail as possible:
- The environment you're using (OS, PowerShell version).
- Steps to reproduce the issue.
- Expected behavior vs actual behavior.

### Suggesting Features

Have a feature request or an idea to improve **KubeTidy**? We’d love to hear it! Please **open an issue** with:
- A clear and concise description of the feature.
- Specific use cases or examples of why this feature would be helpful.

### Submitting a Pull Request (PR)

Once you've made your changes, please submit a PR:
1. **Test** your changes locally to ensure everything works as expected.
2. Push your branch to your fork:

   ```bash
   git push origin feature/my-new-feature
   ```

3. Open a **Pull Request**:
   - Go to your fork on GitHub and click the **"New pull request"** button.
   - Choose your branch and submit the PR to the `main` branch of **KubeTidy**.
   - Provide a clear and detailed description of your changes.

### Code Standards

- **Code Style**: Follow PowerShell best practices and conventions.
- **Comments**: Use comments to explain why certain changes were made, especially for complex logic.
- **Commit Messages**: Use meaningful commit messages (e.g., "Fix issue with cluster cleanup logic" rather than "Fix bug").

### Pull Request Review Process

All contributions will be reviewed by maintainers. Please be patient, as it may take some time depending on the workload. Reviews may involve:
- Suggesting code improvements.
- Requesting more information on the changes.
- Testing changes locally before merging.

## Code of Conduct

Please follow our [Code of Conduct](https://github.com/PixelRobots/KubeTidy/blob/main/CODE_OF_CONDUCT.md) to ensure a welcoming and respectful environment for all contributors.

## Thank You!

Thanks again for contributing to **KubeTidy**! We appreciate your effort in helping to improve the project. 🎉
