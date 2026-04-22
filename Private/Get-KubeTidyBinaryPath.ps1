function Get-KubeTidyBinaryPath {
    [CmdletBinding()]
    param()

    $moduleRoot = $PSScriptRoot | Split-Path -Parent
    $repoRoot = $moduleRoot

    $osName = if ($IsMacOS) { 'darwin' } elseif ($IsLinux) { 'linux' } else { 'windows' }
    $archName = switch ([System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()) {
        'x64' { 'amd64' }
        'arm64' { 'arm64' }
        default { [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant() }
    }
    $binaryNames = if ($osName -eq 'windows') { @('kubetidy.exe', 'kubectl-KubeTidy.exe') } else { @('kubetidy', 'kubectl-KubeTidy') }

    $sourcePaths = @(
        (Join-Path -Path $repoRoot -ChildPath 'cmd'),
        (Join-Path -Path $repoRoot -ChildPath 'internal'),
        (Join-Path -Path $repoRoot -ChildPath 'go.mod'),
        (Join-Path -Path $repoRoot -ChildPath 'go.sum')
    ) | Where-Object { Test-Path -Path $_ }

    $latestSourceWrite = $null
    foreach ($sourcePath in $sourcePaths) {
        if ((Get-Item -Path $sourcePath).PSIsContainer) {
            $latestChild = Get-ChildItem -Path $sourcePath -Recurse -File | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
            if ($latestChild -and ((-not $latestSourceWrite) -or $latestChild.LastWriteTimeUtc -gt $latestSourceWrite)) {
                $latestSourceWrite = $latestChild.LastWriteTimeUtc
            }
        }
        else {
            $item = Get-Item -Path $sourcePath
            if ((-not $latestSourceWrite) -or $item.LastWriteTimeUtc -gt $latestSourceWrite) {
                $latestSourceWrite = $item.LastWriteTimeUtc
            }
        }
    }

    foreach ($binaryName in $binaryNames) {
        $candidate = Join-Path -Path $moduleRoot -ChildPath "bin/$osName-$archName/$binaryName"
        if (Test-Path -Path $candidate) {
            $candidateItem = Get-Item -Path $candidate
            if ($latestSourceWrite -and $candidateItem.LastWriteTimeUtc -lt $latestSourceWrite) {
                break
            }
            if ($osName -ne 'windows') {
                try {
                    $null = & /bin/chmod 755 $candidate 2>$null
                }
                catch {
                }
            }
            return $candidate
        }
    }

    foreach ($commandName in @('kubetidy', 'kubectl-KubeTidy')) {
        $existing = Get-Command -Name $commandName -ErrorAction SilentlyContinue
        if ($existing) {
            return $existing.Source
        }
    }

    $go = Get-Command -Name go -ErrorAction SilentlyContinue
    if (-not $go) {
        throw "kubetidy binary not found and Go is not installed to build it."
    }

    $candidate = Join-Path -Path $moduleRoot -ChildPath "bin/$osName-$archName/$($binaryNames[0])"
    $null = New-Item -ItemType Directory -Path (Split-Path -Parent $candidate) -Force
    $result = & $go.Source -C $repoRoot build -o $candidate ./cmd/kubetidy 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to build kubetidy binary: $($result -join [Environment]::NewLine)"
    }

    if ($osName -ne 'windows') {
        try {
            $null = & /bin/chmod 755 $candidate 2>$null
        }
        catch {
        }
    }

    return $candidate
}
