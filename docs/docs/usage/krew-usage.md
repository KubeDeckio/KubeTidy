---
title: Krew Plugin Usage
parent: Usage
nav_order: 2
layout: default
---

# Krew Plugin Usage

If you're using **KubeTidy** via Krew as a `kubectl` plugin (Linux/macOS), here are the usage examples to help you manage your `kubeconfig` files.

## Clean Up Unreachable Clusters

To clean up unreachable clusters from your `kubeconfig`, use the following command:

```bash
kubectl kubetidy -kubeconfig "$HOME/.kube/config" -exclusionlist "cluster1,cluster2"
```

## Merging Kubeconfig Files

To merge multiple `kubeconfig` files into a single one:

```bash
kubectl kubetidy -mergeconfigs "config1.yaml" "config2.yaml" -destinationconfig "$HOME/.kube/config"
```

## Listing Clusters

To list all clusters in your `kubeconfig` without making changes:

```bash
kubectl kubetidy -kubeconfig "$HOME/.kube/config" -listclusters
```

## Listing Contexts

To list all contexts in your `kubeconfig`:

```bash
kubectl kubetidy -kubeconfig "$HOME/.kube/config" -listcontexts
```

## Dry Run Mode

Use the `-dryrun` option to simulate the cleanup process without modifying your `kubeconfig`:

```bash
kubectl kubetidy -kubeconfig "$HOME/.kube/config" -exclusionlist "cluster1" -dryrun
```

The Dry Run Mode also works for merging multiple kubeconfig files. This allows you to preview a summary of the merge without making any actual changes to the destination file.

```bash
kubectl kubetidy -mergeconfigs "config1.yaml" "config2.yaml" -destinationconfig "$HOME/.kube/config" -dryrun
```


For detailed logging examples, check out our [Logging and Output](../logging-output) page.
