function Get-KubeConfigPath {
    param (
        [string]$KubeConfigPath
    )

    # Check if KubeConfigPath was provided; if not, determine the correct path
    if (-not $KubeConfigPath) {
        function Test-WSL {
            if (Test-Path "/proc/version") {
                $versionInfo = Get-Content "/proc/version"
                return $versionInfo -match "Microsoft"
            }
            return $false
        }

        if ($IsWindows) {
            $KubeConfigPath = "$env:USERPROFILE\.kube\config"
        }
        elseif (Test-WSL) {
            # If running in WSL, get the Windows kubeconfig path
            $windowsHomePath = wslpath "$(wslvar USERPROFILE)"
            $KubeConfigPath = "$windowsHomePath/.kube/config"

            if (-not (Test-Path $KubeConfigPath)) {
                Write-Error "Could not locate the Windows .kube config path in WSL."
                return $null
            }
        }
        else {
            # For native Linux/macOS
            $KubeConfigPath = "$HOME/.kube/config"
        }
        
        Write-Host "KubeConfig Path: $KubeConfigPath" -ForegroundColor Yellow
    }

    # Return the KubeConfigPath
    return $KubeConfigPath
}