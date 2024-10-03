---
title: Release Process
parent: Documentation
nav_order: 4
layout: default
---

# Release Process

This page describes the release process for **KubeTidy**, which involves using GitHub Actions to automate the release of the module to the PowerShell Gallery, the Krew plugin, and to update the documentation.

## How to Create and Push a Tag

To release a new version of **KubeTidy**, you need to tag the release in Git. Tags should follow [semantic versioning](https://semver.org/) (e.g., `v1.0.0`).

### Steps to Tag and Push a Release

1. **Create a Tag**: In your local Git repository, create a tag with the version you want to release. Replace `v1.0.0` with your version number.
   ```bash
   git tag v1.0.0
   ```

2. **Push the Tag to GitHub**: After creating the tag, push it to GitHub.
   ```bash
   git push origin v1.0.0
   ```

3. **GitHub Actions**: Once the tag is pushed, the GitHub Actions workflows will be automatically triggered to publish the release to the PowerShell Gallery and Krew.

## GitHub Pages Deployment

The **Deploy Jekyll Site to Pages** action runs only when changes are pushed to the `docs/` folder. This ensures that the GitHub Pages site is updated only when the documentation is modified, avoiding unnecessary builds and deployments when there are no documentation changes.

### Triggering the Pages Action

The GitHub Pages action is triggered when:
- A commit is pushed to the `main` branch that affects files in the `docs/` folder.
- The workflow is manually triggered through GitHub's Actions tab.

## GitHub Actions Workflows

We use several GitHub Actions workflows to automate the release process. You can view the full details of these workflows directly in the repository:

1. **[Publish Module to PowerShell Gallery](https://github.com/PixelRobots/KubeTidy/blob/main/.github/workflows/publish-psgal.yml)**: This action publishes the KubeTidy PowerShell module to the PowerShell Gallery when a tag is pushed.
  
2. **[Publish Plugin to Krew](https://github.com/PixelRobots/KubeTidy/blob/main/.github/workflows/publish-krewplugin.yaml)**: This action packages and publishes the KubeTidy plugin for Linux and macOS, and uploads it to GitHub as release assets.

3. **[Deploy Jekyll Site to Pages](https://github.com/PixelRobots/KubeTidy/blob/main/.github/workflows/deploy-docs.yml)**: This action builds and deploys the documentation site to GitHub Pages when changes are pushed to the `docs/` folder.

## Summary

These actions automate the release process and make it easy to manage releases across multiple platforms.

For more details, please refer to the [workflows folder](https://github.com/PixelRobots/KubeTidy/tree/main/.github/workflows) in the repository.