#!/usr/bin/env pwsh

$privatePath = Join-Path -Path $PSScriptRoot -ChildPath 'Private'

foreach ($scriptName in 'Get-KubeTidyBinaryPath.ps1', 'Invoke-KubeTidyBinary.ps1') {
    . (Join-Path -Path $privatePath -ChildPath $scriptName)
}

function Invoke-KubeTidy {
    [CmdletBinding()]
    param (
        [string]$KubeConfigPath,
        [array]$ExclusionList,
        [bool]$Backup = $true,
        [switch]$Force,
        [switch]$ListClusters,
        [switch]$ListContexts,
        [switch]$Report,
        [switch]$Doctor,
        [string]$ExportContexts = "",
        [array]$MergeConfigs,
        [string]$DestinationConfig,
        [switch]$DryRun,
        [int]$ProbeTimeoutSeconds = 5,
        [ValidateSet("text", "json", "yaml")] [string]$Output = "text",
        [ValidateSet("keep-first", "keep-last", "fail-on-conflict")] [string]$MergeStrategy = "keep-first",
        [switch]$UI,
        [Alias("h")] [switch]$Help
    )

    $args = @()
    if ($KubeConfigPath) { $args += @('--kubeconfig', $KubeConfigPath) }
    if ($ExclusionList) {
        $exclusions = @($ExclusionList | ForEach-Object { $_.ToString() } | Where-Object { $_.Trim() -ne '' })
        if ($exclusions.Count -gt 0) {
            $args += @('--exclusionlist', ($exclusions -join ','))
        }
    }
    if (-not $Backup) { $args += @('--backup=false') }
    if ($Force) { $args += '--force' }
    if ($ListClusters) { $args += '--listclusters' }
    if ($ListContexts) { $args += '--listcontexts' }
    if ($Report) { $args += '--report' }
    if ($Doctor) { $args += '--doctor' }
    if ($ExportContexts) { $args += @('--exportcontexts', $ExportContexts) }
    foreach ($configPath in @($MergeConfigs | Where-Object { $_ })) {
        $args += @('--mergeconfigs', $configPath)
    }
    if ($DestinationConfig) { $args += @('--destinationconfig', $DestinationConfig) }
    if ($DryRun) { $args += '--dryrun' }
    if ($PSBoundParameters.ContainsKey('ProbeTimeoutSeconds')) { $args += @('--probe-timeout-seconds', $ProbeTimeoutSeconds.ToString()) }
    if ($Output) { $args += @('--output', $Output) }
    if ($MergeStrategy) { $args += @('--merge-strategy', $MergeStrategy) }
    if ($UI) { $args += '--ui' }
    if ($Help) { $args += '--help' }
    if ($PSBoundParameters.ContainsKey('Verbose')) { $args += '--verbose' }

    Invoke-KubeTidyBinary -Arguments $args
}
