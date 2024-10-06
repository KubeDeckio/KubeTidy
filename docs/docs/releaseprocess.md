---
title: Release Process
parent: Documentation
nav_order: 4
layout: default
---

# Release Process

This page describes the release process for KubeTidy, which involves using GitHub Actions to automate the release of the module to the PowerShell Gallery, the Krew plugin, deploying documentation updates to GitHub Pages, and previewing website changes in pull requests.

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

## PR Preview Deployment
For pull requests that modify documentation, we have added a new GitHub Action to automatically deploy a preview of the updated website. This allows you to review how the documentation will look before merging the PR into the main branch.

### How PR Previews Work
The Deploy PR CI action uses the rossjrw/pr-preview-action to generate a preview of the website. When a pull request affecting files in the docs/ folder is opened or updated, this action is triggered to build and deploy a preview of the documentation changes.

The preview site is deployed to a unique URL using the following structure:

```bash
/pr-preview/pr-<PR_number>
```

This allows reviewers to easily view the proposed changes as they would appear on the live site before merging the PR.

### Triggering the PR Preview Action
The PR preview action is triggered when:

A pull request affecting files in the docs/ folder is opened, updated, or reopened.
The pull request is closed (the preview environment is cleaned up).

## GitHub Actions Workflows

We use several GitHub Actions workflows to automate the release process. You can view the full details of these workflows directly in the repository:

1. **[Publish Module to PowerShell Gallery](https://github.com/PixelRobots/KubeTidy/blob/main/.github/workflows/publish-psgal.yml)**: This action publishes the KubeTidy PowerShell module to the PowerShell Gallery when a tag is pushed.
  
2. **[Publish Plugin to Krew](https://github.com/PixelRobots/KubeTidy/blob/main/.github/workflows/publish-krewplugin.yaml)**: This action packages and publishes the KubeTidy plugin for Linux and macOS, and uploads it to GitHub as release assets.

3. **[Deploy Jekyll Site to Pages](https://github.com/PixelRobots/KubeTidy/blob/main/.github/workflows/deploy-docs.yml)**: This action builds and deploys the documentation site to GitHub Pages when changes are pushed to the `docs/` folder.

4. **[Deploy PR Preview](https://github.com/PixelRobots/KubeTidy/blob/main/.github/workflows/deploy-pr.yaml)**: This action builds and deploys a preview of the website for pull requests affecting the `docs/` folder.

## Summary

These actions automate the release process and make it easy to manage releases across multiple platforms. The addition of PR previews enhances the review process by allowing contributors to see how documentation updates will appear on the live site before merging.

For more details, please refer to the [workflows folder](https://github.com/PixelRobots/KubeTidy/tree/main/.github/workflows) in the repository.
