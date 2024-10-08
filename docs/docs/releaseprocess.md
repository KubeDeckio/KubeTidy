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

## Netlify PR Previews for Documentation
When a pull request that affects the `docs/` folder is opened or updated, Netlify automatically deploys a preview of the updated website. This allows you to review the documentation changes in a live environment before merging the pull request.

### Reviewing Documentation with Netlify Previews
For each pull request, a unique preview URL will be posted as a comment. Before merging, reviewers should check this preview to ensure the documentation appears as expected.

Make sure to always review the Netlify preview to confirm that the changes render correctly on the website.

## GitHub Actions Workflows

We use several GitHub Actions workflows to automate the release process. You can view the full details of these workflows directly in the repository:

1. **[Publish Module to PowerShell Gallery](https://github.com/PixelRobots/KubeTidy/blob/main/.github/workflows/publish-psgal.yml)**: This action publishes the KubeTidy PowerShell module to the PowerShell Gallery when a tag is pushed.
  
2. **[Publish Plugin to Krew](https://github.com/PixelRobots/KubeTidy/blob/main/.github/workflows/publish-krewplugin.yaml)**: This action packages and publishes the KubeTidy plugin for Linux and macOS, and uploads it to GitHub as release assets.

3. **[Deploy Jekyll Site to Pages](https://github.com/PixelRobots/KubeTidy/blob/main/.github/workflows/deploy-docs.yml)**: This action builds and deploys the documentation site to GitHub Pages when changes are pushed to the `docs/` folder.

4. **Netlify PR Previews**: Netlify automatically builds and deploys documentation previews for pull requests affecting the `docs/` folder.

5. **[Run PSScriptAnalyzer on Pull Requests](https://github.com/PixelRobots/KubeTidy/blob/main/.github/workflows/PSScriptAnalyzer.yaml)**: This workflow triggers **PSScriptAnalyzer** on every pull request to the `main` branch. It scans PowerShell scripts for code quality, ensuring no warnings or errors are present before merging changes. The results are displayed directly in the GitHub Actions summary as formatted Markdown tables.

## Code Quality and Linting

As part of our commitment to code quality, we run **PSScriptAnalyzer** to scan all PowerShell scripts for any warnings or errors before publishing a new release. This ensures the code meets the required standards before it is made available to the PowerShell Gallery and Krew.

### Automated Code Analysis with PSScriptAnalyzer

We have a GitHub Action in place that triggers **PSScriptAnalyzer** whenever a pull request is opened or updated against the `main` branch. This action performs the following tasks:

- Scans all PowerShell scripts within the repository.
- Checks for potential issues such as rule violations, warnings, and errors.
- Formats the results into Markdown tables, which are appended to the GitHub Actions summary for easy review.
- Fails the build if any errors are detected, preventing the release from proceeding with faulty code.

### How It Integrates with the Release Process

This action is a crucial part of our release process and runs alongside the existing workflows that publish the module to the PowerShell Gallery and Krew. Specifically, the **PSScriptAnalyzer** check ensures that any release tagged for publication meets code quality standards before it is pushed out.

By incorporating this analysis step, we safeguard the code from potential issues and maintain high standards for every release. The release process will not continue until the PSScriptAnalyzer successfully passes, ensuring that only compliant code is published.

## Summary

These workflows automate the release process and manage releases across multiple platforms. With Netlify PR previews, contributors and reviewers can verify how documentation updates will appear on the website before they are merged into the `main` branch.

For more details, please refer to the [workflows folder](https://github.com/PixelRobots/KubeTidy/tree/main/.github/workflows) in the repository.
