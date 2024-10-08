# Function to check if a cluster is reachable using HTTPS request
function Test-ClusterReachability {
    [CmdletBinding()]
    param (
        [string]$ClusterServer
    )
    try {
        Write-Verbose "Testing reachability for cluster server: $ClusterServer"
        $response = Invoke-WebRequest -Uri $ClusterServer -UseBasicParsing -TimeoutSec 5 -SkipCertificateCheck -ErrorAction Stop
        Write-Verbose "Cluster $ClusterServer is reachable."
        return $true
    }
    catch {
        if ($_.Exception.Response) {
            Write-Verbose "Cluster $ClusterServer is reachable but returned an error (e.g., 401 Unauthorized)."
            return $true  # Server is reachable but returned an error like 401
        }
        else {
            Write-Verbose "Cluster $ClusterServer is unreachable due to error: $($_.Exception.Message)"
            return $false
        }
    }
}